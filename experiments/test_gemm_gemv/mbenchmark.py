#!/usr/bin/env python

# This file is part of the CLBlast project. The project is licensed under Apache Version 2.0. This file follows the
# PEP8 Python style guide and uses a max-width of 120 characters per line.
#
# Author(s):
#   Cedric Nugteren <www.cedricnugteren.nl>

import argparse
import copy
import csv
import json
import os
import sys
import concurrent.futures

import msettings
import matplotlib.pyplot as plt
import subprocess

EXPERIMENTS = {
    "cpu_igpu": msettings.CPU_IGPU_CORUN,
}

def run_binary(command, arguments):
    full_command = command + " " + " ".join(arguments)
    print("[benchmark] Calling binary: %s" % str(full_command))
    try:
        result = subprocess.Popen(full_command, shell=True, stdout=subprocess.PIPE).stdout.read()
        return result.decode("ascii")
    except OSError as e:
        print("[benchmark] Error while running the binary, got exception: %s" + str(e))
        return False

def parse_results(csv_data):
    csv_data = csv_data.split("\n")
    results = csv.DictReader(csv_data, delimiter=";", skipinitialspace=True)
    results = [r for r in results]
    for result in results:
        for key in result:
            if "i" in result[key]:
                continue
            else:
                result[key] = float(result[key]) if "." in result[key] else int(result[key])
    return results

def get_bench_args(devices, precisions, num_steps, num_runs):
    constant_arguments = ["-warm_up", "-q", "-no_abbrv"]
    for precision in precisions:
        for n_step in range(num_steps):
            devices_args = []
            for device in copy.deepcopy(devices):
                common_arguments = ["-precision %d" % precision, "-runs %d" % num_runs]
                opencl_arguments = ["-platform %d" % device["platform"], "-device %d" % device["device"]]
                all_arguments = opencl_arguments + common_arguments + constant_arguments
                if device["custom_step"] is not None:
                    for name, value in device["custom_step"].items():
                        device["args"][name] += value * n_step
                for name, value in device["args"].items():
                    all_arguments.append("-" + name + " " + str(value))
                devices_args.append((device["name"], all_arguments))
            yield devices_args, precision, n_step

def run_benchmark(name, num_steps, num_runs, devices, precisions):
    if len(devices) == 0:
        print("need to specify devices")
        return []

    binary = "./clblast_client_x" + name

    # Loops over sub-benchmarks per benchmark
    results = {}
    for device in devices:
        results[device["name"]] = {}

    with concurrent.futures.ThreadPoolExecutor(max_workers=len(devices)) as executor:
        for devices_args, precision, _ in get_bench_args(devices, precisions, num_steps, num_runs):
            # multi-thread execution
            futures = []
            for device_name, all_arguments in devices_args:
                # Calls the binary 
                future = executor.submit(run_binary, binary, all_arguments)
                futures.append((device_name, future))

            # get output
            for device_name, future in futures:
                ret_val = future.result()
                benchmark_output = parse_results(ret_val)
                if precision not in results[device_name]:
                    results[device_name][precision] = benchmark_output
                else:
                    results[device_name][precision].extend(benchmark_output)
                    
    return results


def parse_arguments(argv):
    parser = argparse.ArgumentParser(description="Runs a full benchmark for a specific routine on a specific device")
    parser.add_argument("-b", "--benchmark", required=True, help="The benchmark to perform (choose from %s)" % sorted(EXPERIMENTS.keys()))
    parser.add_argument("-l", "--load_from_disk", action="store_true", help="Loading existing results from JSON file and replot")
    parser.add_argument("-o", "--output_folder", default=os.getcwd(), help="Sets the folder for output plots (defaults to current folder)")
    parser.add_argument("-v", "--verbose", action="store_true", help="Increase verbosity of the script")
    cl_args = parser.parse_args(argv)
    return vars(cl_args)


def benchmark_single(benchmark, load_from_disk, output_folder, verbose):

    # Sanity check
    if not os.path.isdir(output_folder):
        print("[benchmark] Error: folder '%s' doesn't exist" % output_folder)
        return

    # The benchmark name and plot title
    benchmark_name = benchmark.upper()
    plot_title = benchmark_name

    # Retrieves the benchmark settings
    if benchmark not in EXPERIMENTS.keys():
        print("[benchmark] Invalid benchmark '%s', choose from %s" % (benchmark, EXPERIMENTS.keys()))
        return
    experiment = EXPERIMENTS[benchmark]
    benchmarks = experiment["benchmarks"]

    # Either run the benchmarks for this experiment or load old results from disk
    json_file_name = os.path.join(output_folder, benchmark_name.lower() + "_benchmarks.json")
    if load_from_disk and os.path.isfile(json_file_name):
        print("[benchmark] Loading previous benchmark results from '" + json_file_name + "'")
        with open(json_file_name) as f:
            results = json.load(f)
    else:
        # Runs all the individual benchmarks
        # print("[benchmark] Running on platform %d, device %d" % (platform, device))
        print("[benchmark] Running %d benchmarks for settings '%s'" % (len(benchmarks), benchmark))
        results = []
        for bench in benchmarks:
            print("[benchmark] Running benchmark '%s:%s'" % (bench["name"], bench["title"]))
            bench["benchmark"] = run_benchmark(bench["name"], bench["num_steps"], bench["num_runs"], bench["devices"], bench["precisions"])
            results.append(bench)

        # Stores the results to disk
        print("[benchmark] Saving benchmark results to '" + json_file_name + "'")
        with open(json_file_name, "w") as f:
            json.dump(results, f, sort_keys=True, indent=4)

    for result in results:
        plot_graph(result)
    
    print("[benchmark] All done")

def get_plot_color():
    # loop plt color
    # when called, return a next color
    color_list = ["red", "blue", "green", "yellow", "black", "pink", "purple", "orange"]
    index = 0
    while True:
        yield color_list[index]
        index = (index + 1) % len(color_list)

def plot_graph(result: dict):
    plot_name = str(result["title"]).replace(" ", "_")
    x_title = result["x_label"]
    # format x label
    x_label:list[str] = ["" for _ in range(result["num_steps"])]
    for device, bench_val in result["benchmark"].items():
        for precision, data in bench_val.items():
            for index, bench_data in enumerate(data):
                label = f"{device}\n("
                for key in result["x_keys"]:
                    label += str(bench_data[key]) + ","
                label += ")"
                if x_label[index] != "":
                    x_label[index] += "\n"
                x_label[index] += label
    # get GFLOPS/GBS y range and lables
    gbs_y = {}
    gflops_y = {}
    for device, bench_val in result["benchmark"].items():
        for precision, data in bench_val.items():
            key = f"{device}_{precision}"
            gbs_y[key] = []
            gflops_y[key] = []
            for b_data in data:
                gbs_y[key].append(b_data["GBs_1"])
                gflops_y[key].append(b_data["GFLOPS_1"])

    # plot gflops
    plt.clf()
    # 创建一个图形和两个子图
    fig, axs = plt.subplots(2, 1, figsize=(16, 14))  # 2行1列的子图

    axs[0].set_title(f"{plot_name}_gflops")
    axs[0].set_xlabel(x_title)
    axs[0].set_ylabel("GFLOPS")
    # range of y axis
    min_y, max_y = sys.float_info.max, 0.0
    # every data in gflops_y, with name of key, use different color
    for key, y in gflops_y.items():
        min_y = min(min_y, min(y))
        max_y = max(max_y, max(y))
        axs[0].plot(x_label, y, label=key, marker='.')
    if len(gflops_y) > 1:
        sum = []
        for key, y in gflops_y.items():
            if len(sum) == 0:
                sum = y
            else:
                sum = [a + b for a, b in zip(sum, y)]
        max_y = max(max_y, max(sum))
        axs[0].plot(x_label, sum, label="sum", marker='.')
    axs[0].set_ylim(max(min_y - 5, 0), max_y + 5)
    # 添加图例，设置位置为右上角
    axs[0].legend(loc='upper right')

    # plot gbs
    axs[1].set_title(f"{plot_name}_gbs")
    axs[1].set_xlabel(x_title)
    axs[1].set_ylabel("GB/s")
    # range of y axis
    min_y, max_y = sys.float_info.max, 0.0
    # every data in gbs_y, with name of key, use different color
    for key, y in gbs_y.items():
        min_y = min(min_y, min(y))
        max_y = max(max_y, max(y))
        axs[1].plot(x_label, y, label=key, marker='.')
    if len(gbs_y) > 1:
        sum = []
        for key, y in gbs_y.items():
            if len(sum) == 0:
                sum = y
            else:
                sum = [a + b for a, b in zip(sum, y)]
        max_y = max(max_y, max(sum))
        axs[1].plot(x_label, sum, label="sum", marker='.')
    axs[1].set_ylim(max(min_y - 5, 0), max_y + 5)
    # 添加图例，设置位置为右上角
    axs[1].legend(loc='upper right')

    # 调整子图的布局
    plt.tight_layout()
    plt.savefig(f"{plot_name}.png")

    





if __name__ == '__main__':
    parsed_arguments = parse_arguments(sys.argv[1:])
    benchmark_single(**parsed_arguments)
