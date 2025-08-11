#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys


DEVICE_NAME = "'Intel(R) Arc(TM) Graphics'"
ENV_ARGS = "GGML_OPENCL_DEVICE=" + DEVICE_NAME
COMBO_BENCH_PATH = "./build/release/bin/combo_bench "
MODEL_BASE = "/home/lx/code/model/gguf"
# batch, pp len, tg len, repeat, kv cache len
MODELS_ARGS = {
    "llama-2-7b.Q4_K_M.gguf": " 1 64,128,256,512,1024,2048,4096,8192 32 11",
    "llama-2-7b.Q8_0.gguf": " 1 64,128,256,512,1024,2048,4096,8192 32 11",
    "llama-2-7b.fp16.gguf": " 1 64,128,256,512,1024,2048,4096,8192 32 11 ",
    "baichuan2-7b-chat.Q4_K.gguf": " 1 64,128,256,512,1024,2048,4096,8192 32 11",
    "baichuan2-7b-chat.Q8_0.gguf": " 1 64,128,256,512,1024,2048,4096,8192 32 11",
    "baichuan2-7b-chat.gguf": " 1 64,128,256,512,1024,2048,4096,8192 32 11 "
}
# batch, pp len, tg len, repeat
# COMBO_BENCH_ARGS = " 1 128,256,384,512,1024,2048,4096 32 20 "
# COMBO_BENCH_ARGS = " 1 128 4 1 "

BENCH_TARGET_SET = {
    0: "gd",
    1: "cold_start",
    2: "const_ratio",
    3: "cpu_only",
    4: "igpu_only",
}

TEST_RESULT_START_LINE = "COMBO_TEST_STRAT"
def store_result_to_csv_file(result: str, out_dir: str, model_name: str, target: int) -> int:
    lines = result.split("\n")
    start_line = -1
    for i, line in enumerate(lines):
        if TEST_RESULT_START_LINE in line:
            start_line = i + 1
            break
    if start_line == -1:
        print("[benchmark] Error: Cannot find the start line of the test result")
        return 1
    # check model_name directory
    base_dir = os.path.join(out_dir, model_name)
    if not os.path.exists(base_dir):
        os.makedirs(base_dir)
    out_file = base_dir + "/" + BENCH_TARGET_SET[target] + ".csv"
    # if out_file exist, backup it
    if os.path.exists(out_file):
        os.rename(out_file, out_file + ".bak")
    # write lines[start_line:] to file line by line
    with open(out_file, "w") as f:
        for line in lines[start_line:]:
            # remove all spece inside line
            line = line.replace(" ", "")
            if line == "" or line == "\n":
                continue
            f.write(line + "\n")
    return 0

def get_combo_bench_cmd(model_name: str, target: int) -> str:
    return str.join(" ", [ENV_ARGS, COMBO_BENCH_PATH, os.path.join(MODEL_BASE, model_name), MODELS_ARGS[model_name], str(target), "10000"])

def run_combo_bench(model_name: str, target: int) -> str:
    cmd = get_combo_bench_cmd(model_name, target)
    print("[benchmark] Calling binary: %s" % cmd)
    try:
        result = subprocess.Popen(cmd, shell=True, stdout=None, stderr=subprocess.PIPE).stderr.read()
        return result.decode("ascii")
    except OSError as e:
        print("[benchmark] Error while running the binary, got exception: %s" + str(e))
        return False

def parse_arguments(argv):
    parser = argparse.ArgumentParser(description="Runs a full benchmark for a specific model on a specific device")
    parser.add_argument("-o", "--output_folder", default=os.getcwd() + "/eval_result", help="Sets the folder for output plots (defaults to current folder)")
    cl_args = parser.parse_args(argv)
    return vars(cl_args)

def main() -> None:
    parsed_arguments = parse_arguments(sys.argv[1:])
    out_dir = parsed_arguments["output_folder"]
    for model in MODELS_ARGS:
        for target in BENCH_TARGET_SET:
            result = run_combo_bench(model, target)
            store_result_to_csv_file(result, out_dir, model, target)

if __name__ == '__main__':
    main()
