# Define the default target now so that it is always the first target
BUILD_TARGETS = \
	main quantize quantize-stats perplexity embedding vdot q8dot train-text-from-scratch convert-llama2c-to-ggml \
	simple batched batched-bench save-load-state server gguf llama-bench libllava.a llava-cli baby-llama beam-search  \
	speculative infill tokenize benchmark-matmult parallel finetune export-lora lookahead tests/test-c.o

# Binaries only useful for tests
TEST_TARGETS = \
	tests/test-llama-grammar tests/test-grammar-parser tests/test-double-float tests/test-grad0 tests/test-opt \
	tests/test-quantize-fns tests/test-quantize-perf tests/test-sampling tests/test-tokenizer-0-llama          \
	tests/test-tokenizer-0-falcon tests/test-tokenizer-1-llama tests/test-tokenizer-1-bpe

# Code coverage output files
COV_TARGETS = *.gcno tests/*.gcno *.gcda tests/*.gcda *.gcov tests/*.gcov lcov-report gcovr-report

ifndef UNAME_S
UNAME_S := $(shell uname -s)
endif

ifndef UNAME_P
UNAME_P := $(shell uname -p)
endif

ifndef UNAME_M
UNAME_M := $(shell uname -m)
endif

ifeq '' '$(findstring clang,$(shell $(CC) --version))'
	CC_IS_GCC=1
	CC_VER := $(shell $(CC) -dumpfullversion -dumpversion | awk -F. '{ printf("%02d%02d%02d", $$1, $$2, $$3) }')
else
	CC_IS_CLANG=1
	ifeq '' '$(findstring Apple LLVM,$(shell $(CC) --version))'
		CC_IS_LLVM_CLANG=1
	else
		CC_IS_APPLE_CLANG=1
	endif
	CC_VER := $(shell $(CC) --version | sed -n 's/^.* version \([0-9.]*\).*$$/\1/p' \
				| awk -F. '{ printf("%02d%02d%02d", $$1, $$2, $$3) }')
endif


default: $(BUILD_TARGETS)

test: $(TEST_TARGETS)
	@failures=0; \
	for test_target in $(TEST_TARGETS); do \
		if [ "$$test_target" = "tests/test-tokenizer-0-llama" ]; then \
			./$$test_target $(CURDIR)/models/ggml-vocab-llama.gguf; \
		elif [ "$$test_target" = "tests/test-tokenizer-0-falcon" ]; then \
			./$$test_target $(CURDIR)/models/ggml-vocab-falcon.gguf; \
		elif [ "$$test_target" = "tests/test-tokenizer-1-llama" ]; then \
			continue; \
		elif [ "$$test_target" = "tests/test-tokenizer-1-bpe" ]; then \
			continue; \
		else \
			echo "Running test $$test_target..."; \
			./$$test_target; \
		fi; \
		if [ $$? -ne 0 ]; then \
			printf 'Test $$test_target FAILED!\n\n' $$test_target; \
			failures=$$(( failures + 1 )); \
		else \
			printf 'Test %s passed.\n\n' $$test_target; \
		fi; \
	done; \
	if [ $$failures -gt 0 ]; then \
		printf '\n%s tests failed.\n' $$failures; \
		exit 1; \
	fi
	@echo 'All tests passed.'

all: $(BUILD_TARGETS) $(TEST_TARGETS)

coverage: ## Run code coverage
	gcov -pb tests/*.cpp

lcov-report: coverage ## Generate lcov report
	mkdir -p lcov-report
	lcov --capture --directory . --output-file lcov-report/coverage.info
	genhtml lcov-report/coverage.info --output-directory lcov-report

gcovr-report: coverage ## Generate gcovr report
	mkdir -p gcovr-report
	gcovr --root . --html --html-details --output gcovr-report/coverage.html

#
# Compile flags
#

# keep standard at C11 and C++11
MK_CPPFLAGS = -I. -Icommon
MK_CFLAGS   = -std=c11   -fPIC
MK_CXXFLAGS = -std=c++11 -fPIC

# -Ofast tends to produce faster code, but may not be available for some compilers.
ifdef LLAMA_FAST
MK_CFLAGS        += -Ofast
MK_HOST_CXXFLAGS += -Ofast
else
MK_CFLAGS        += -O3
MK_CXXFLAGS      += -O3
endif

# clock_gettime came in POSIX.1b (1993)
# CLOCK_MONOTONIC came in POSIX.1-2001 / SUSv3 as optional
# posix_memalign came in POSIX.1-2001 / SUSv3
# M_PI is an XSI extension since POSIX.1-2001 / SUSv3, came in XPG1 (1985)
MK_CPPFLAGS += -D_XOPEN_SOURCE=600

# Somehow in OpenBSD whenever POSIX conformance is specified
# some string functions rely on locale_t availability,
# which was introduced in POSIX.1-2008, forcing us to go higher
ifeq ($(UNAME_S),OpenBSD)
	MK_CPPFLAGS += -U_XOPEN_SOURCE -D_XOPEN_SOURCE=700
endif

# Data types, macros and functions related to controlling CPU affinity and
# some memory allocation are available on Linux through GNU extensions in libc
ifeq ($(UNAME_S),Linux)
	MK_CPPFLAGS += -D_GNU_SOURCE
endif



ifdef LLAMA_DEBUG
	MK_CFLAGS   += -O0 -g
	MK_CXXFLAGS += -O0 -g
	MK_LDFLAGS  += -g
else
	MK_CPPFLAGS += -DNDEBUG
endif

ifdef LLAMA_SANITIZE_THREAD
	MK_CFLAGS   += -fsanitize=thread -g
	MK_CXXFLAGS += -fsanitize=thread -g
	MK_LDFLAGS  += -fsanitize=thread -g
endif

ifdef LLAMA_SANITIZE_ADDRESS
	MK_CFLAGS   += -fsanitize=address -fno-omit-frame-pointer -g
	MK_CXXFLAGS += -fsanitize=address -fno-omit-frame-pointer -g
	MK_LDFLAGS  += -fsanitize=address -fno-omit-frame-pointer -g
endif

ifdef LLAMA_SANITIZE_UNDEFINED
	MK_CFLAGS   += -fsanitize=undefined -g
	MK_CXXFLAGS += -fsanitize=undefined -g
	MK_LDFLAGS  += -fsanitize=undefined -g
endif

ifdef LLAMA_SERVER_VERBOSE
	MK_CPPFLAGS += -DSERVER_VERBOSE=$(LLAMA_SERVER_VERBOSE)
endif


ifdef LLAMA_CODE_COVERAGE
	MK_CXXFLAGS += -fprofile-arcs -ftest-coverage -dumpbase ''
endif

ifdef LLAMA_DISABLE_LOGS
	MK_CPPFLAGS += -DLOG_DISABLE_LOGS
endif # LLAMA_DISABLE_LOGS

# warnings
WARN_FLAGS    = -Wall -Wextra -Wpedantic -Wcast-qual -Wno-unused-function
MK_CFLAGS    += $(WARN_FLAGS) -Wshadow -Wstrict-prototypes -Wpointer-arith -Wmissing-prototypes -Werror=implicit-int \
				-Werror=implicit-function-declaration
MK_CXXFLAGS  += $(WARN_FLAGS) -Wmissing-declarations -Wmissing-noreturn

ifeq ($(CC_IS_CLANG), 1)
	# clang options
	MK_CFLAGS        += -Wunreachable-code-break -Wunreachable-code-return
	MK_HOST_CXXFLAGS += -Wunreachable-code-break -Wunreachable-code-return -Wmissing-prototypes -Wextra-semi

	ifneq '' '$(and $(CC_IS_LLVM_CLANG),$(filter 1,$(shell expr $(CC_VER) \>= 030800)))'
		MK_CFLAGS += -Wdouble-promotion
	endif
	ifneq '' '$(and $(CC_IS_APPLE_CLANG),$(filter 1,$(shell expr $(CC_VER) \>= 070300)))'
		MK_CFLAGS += -Wdouble-promotion
	endif
else
	# gcc options
	MK_CFLAGS        += -Wdouble-promotion
	MK_HOST_CXXFLAGS += -Wno-array-bounds

	ifeq ($(shell expr $(CC_VER) \>= 070100), 1)
		MK_HOST_CXXFLAGS += -Wno-format-truncation
	endif
	ifeq ($(shell expr $(CC_VER) \>= 080100), 1)
		MK_HOST_CXXFLAGS += -Wextra-semi
	endif
endif


# OS specific
# TODO: support Windows
ifneq '' '$(filter $(UNAME_S),Linux Darwin FreeBSD NetBSD OpenBSD Haiku)'
	MK_CFLAGS   += -pthread
	MK_CXXFLAGS += -pthread
endif

ifdef LLAMA_GPROF
	MK_CFLAGS   += -pg
	MK_CXXFLAGS += -pg
endif
ifdef LLAMA_PERF
	MK_CPPFLAGS += -DGGML_PERF
endif

# Architecture specific
# TODO: probably these flags need to be tweaked on some architectures
#       feel free to update the Makefile for your architecture and send a pull request or issue

ifeq ($(UNAME_M),$(filter $(UNAME_M),x86_64 i686 amd64))
	# Use all CPU extensions that are available:
	MK_CFLAGS   += -march=native -mtune=native
	MK_HOST_CXXFLAGS += -march=native -mtune=native

	# Usage AVX-only
	#MK_CFLAGS   += -mfma -mf16c -mavx
	#MK_CXXFLAGS += -mfma -mf16c -mavx

	# Usage SSSE3-only (Not is SSE3!)
	#MK_CFLAGS   += -mssse3
	#MK_CXXFLAGS += -mssse3
endif



ifdef LLAMA_QKK_64
	MK_CPPFLAGS += -DGGML_QKK_64
endif

ifndef LLAMA_NO_ACCELERATE
	# Mac OS - include Accelerate framework.
	# `-framework Accelerate` works both with Apple Silicon and Mac Intel
	ifeq ($(UNAME_S),Darwin)
		MK_CPPFLAGS += -DGGML_USE_ACCELERATE
		MK_CPPFLAGS += -DACCELERATE_NEW_LAPACK
		MK_CPPFLAGS += -DACCELERATE_LAPACK_ILP64
		MK_LDFLAGS  += -framework Accelerate
	endif
endif # LLAMA_NO_ACCELERATE

ifdef LLAMA_OPENBLAS
	MK_CPPFLAGS += -DGGML_USE_OPENBLAS $(shell pkg-config --cflags-only-I openblas)
	MK_CFLAGS   += $(shell pkg-config --cflags-only-other openblas)
	MK_LDFLAGS  += $(shell pkg-config --libs openblas)
endif # LLAMA_OPENBLAS

ifdef LLAMA_BLIS
	MK_CPPFLAGS += -DGGML_USE_OPENBLAS -I/usr/local/include/blis -I/usr/include/blis
	MK_LDFLAGS  += -lblis -L/usr/local/lib
endif # LLAMA_BLIS

ifdef LLAMA_CLBLAST

	MK_CPPFLAGS += -DGGML_USE_CLBLAST $(shell pkg-config --cflags-only-I clblast OpenCL)
	MK_CFLAGS   += $(shell pkg-config --cflags-only-other clblast OpenCL)
	MK_CXXFLAGS += $(shell pkg-config --cflags-only-other clblast OpenCL)

	# Mac provides OpenCL as a framework
	ifeq ($(UNAME_S),Darwin)
		MK_LDFLAGS += -lclblast -framework OpenCL
	else
		MK_LDFLAGS += $(shell pkg-config --libs clblast OpenCL)
	endif
	OBJS    += ggml-opencl.o

ggml-opencl.o: ggml-opencl.cpp ggml-opencl.h
	$(CXX) $(CXXFLAGS) -c $< -o $@
endif # LLAMA_CLBLAST


# combine build flags with cmdline overrides
override CFLAGS        := $(MK_CPPFLAGS) $(CPPFLAGS) $(MK_CFLAGS) $(CFLAGS)
override CXXFLAGS      := $(MK_CPPFLAGS) $(CPPFLAGS) $(MK_CXXFLAGS) $(CXXFLAGS)
override HOST_CXXFLAGS := $(MK_HOST_CXXFLAGS) $(HOST_CXXFLAGS)
override LDFLAGS       := $(MK_LDFLAGS) $(LDFLAGS)

# save CXXFLAGS before we add host-only options
NVCCFLAGS := $(NVCCFLAGS) $(CXXFLAGS) -Wno-pedantic -Xcompiler "$(HOST_CXXFLAGS)"
override CXXFLAGS += $(HOST_CXXFLAGS)

#
# Print build information
#

$(info I llama.cpp build info: )
$(info I UNAME_S:   $(UNAME_S))
$(info I UNAME_P:   $(UNAME_P))
$(info I UNAME_M:   $(UNAME_M))
$(info I CFLAGS:    $(CFLAGS))
$(info I CXXFLAGS:  $(CXXFLAGS))
$(info I NVCCFLAGS: $(NVCCFLAGS))
$(info I LDFLAGS:   $(LDFLAGS))
$(info I CC:        $(shell $(CC) --version | head -n 1))
$(info I CXX:       $(shell $(CXX) --version | head -n 1))
$(info )

#
# Build library
#

ggml.o: ggml.c ggml.h
	$(CC)  $(CFLAGS)   -c $< -o $@

ggml-alloc.o: ggml-alloc.c ggml.h ggml-alloc.h
	$(CC)  $(CFLAGS)   -c $< -o $@

ggml-backend.o: ggml-backend.c ggml.h ggml-backend.h
	$(CC)  $(CFLAGS)   -c $< -o $@

ggml-quants.o: ggml-quants.c ggml.h ggml-quants.h
	$(CC) $(CFLAGS)    -c $< -o $@

OBJS += ggml-alloc.o ggml-backend.o ggml-quants.o

llama.o: llama.cpp ggml.h ggml-alloc.h ggml-backend.h llama.h
	$(CXX) $(CXXFLAGS) -c $< -o $@

COMMON_H_DEPS = common/common.h common/sampling.h common/log.h
COMMON_DEPS   = common.o sampling.o grammar-parser.o build-info.o

common.o: common/common.cpp $(COMMON_H_DEPS)
	$(CXX) $(CXXFLAGS) -c $< -o $@

sampling.o: common/sampling.cpp $(COMMON_H_DEPS)
	$(CXX) $(CXXFLAGS) -c $< -o $@

console.o: common/console.cpp common/console.h
	$(CXX) $(CXXFLAGS) -c $< -o $@

grammar-parser.o: common/grammar-parser.cpp common/grammar-parser.h
	$(CXX) $(CXXFLAGS) -c $< -o $@

train.o: common/train.cpp common/train.h
	$(CXX) $(CXXFLAGS) -c $< -o $@

libllama.so: llama.o ggml.o $(OBJS)
	$(CXX) $(CXXFLAGS) -shared -fPIC -o $@ $^ $(LDFLAGS)

clean:
	rm -vrf *.o tests/*.o *.so *.dll benchmark-matmult common/build-info.cpp *.dot $(COV_TARGETS) $(BUILD_TARGETS) $(TEST_TARGETS)

#
# Examples
#

main: examples/main/main.cpp                                  ggml.o llama.o $(COMMON_DEPS) console.o grammar-parser.o $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)
	@echo
	@echo '====  Run ./main -h for help.  ===='
	@echo

infill: examples/infill/infill.cpp                            ggml.o llama.o $(COMMON_DEPS) console.o grammar-parser.o $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

simple: examples/simple/simple.cpp                            ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

tokenize: examples/tokenize/tokenize.cpp                      ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

batched: examples/batched/batched.cpp                         ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

batched-bench: examples/batched-bench/batched-bench.cpp       build-info.o ggml.o llama.o common.o $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

quantize: examples/quantize/quantize.cpp                      build-info.o ggml.o llama.o $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

quantize-stats: examples/quantize-stats/quantize-stats.cpp    build-info.o ggml.o llama.o $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

perplexity: examples/perplexity/perplexity.cpp                ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

embedding: examples/embedding/embedding.cpp                   ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

save-load-state: examples/save-load-state/save-load-state.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

server: examples/server/server.cpp examples/server/httplib.h examples/server/json.hpp examples/server/index.html.hpp examples/server/index.js.hpp examples/server/completion.js.hpp examples/llava/clip.cpp examples/llava/clip.h common/stb_image.h ggml.o llama.o $(COMMON_DEPS) grammar-parser.o $(OBJS)
	$(CXX) $(CXXFLAGS) -Iexamples/server $(filter-out %.h,$(filter-out %.hpp,$^)) -o $@ $(LDFLAGS) $(LWINSOCK2) -Wno-cast-qual

gguf: examples/gguf/gguf.cpp ggml.o llama.o $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

train-text-from-scratch: examples/train-text-from-scratch/train-text-from-scratch.cpp ggml.o llama.o $(COMMON_DEPS) train.o $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

convert-llama2c-to-ggml: examples/convert-llama2c-to-ggml/convert-llama2c-to-ggml.cpp ggml.o llama.o $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

llama-bench: examples/llama-bench/llama-bench.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

libllava.a: examples/llava/llava.cpp examples/llava/llava.h examples/llava/clip.cpp examples/llava/clip.h common/stb_image.h common/base64.hpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) -static -fPIC -c $< -o $@ -Wno-cast-qual

llava-cli: examples/llava/llava-cli.cpp examples/llava/clip.h examples/llava/clip.cpp examples/llava/llava.h examples/llava/llava.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS) -Wno-cast-qual

baby-llama: examples/baby-llama/baby-llama.cpp ggml.o llama.o $(COMMON_DEPS) train.o $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

beam-search: examples/beam-search/beam-search.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

finetune: examples/finetune/finetune.cpp ggml.o llama.o $(COMMON_DEPS) train.o $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

export-lora: examples/export-lora/export-lora.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

speculative: examples/speculative/speculative.cpp ggml.o llama.o $(COMMON_DEPS) grammar-parser.o $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

parallel: examples/parallel/parallel.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

lookahead: examples/lookahead/lookahead.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)


common/build-info.cpp: $(wildcard .git/index) scripts/build-info.sh
	@sh scripts/build-info.sh $(CC) > $@.tmp
	@if ! cmp -s $@.tmp $@; then \
		mv $@.tmp $@; \
	else \
		rm $@.tmp; \
	fi

build-info.o: common/build-info.cpp
	$(CXX) $(CXXFLAGS) -c $(filter-out %.h,$^) -o $@

#
# Tests
#

tests: $(TEST_TARGETS)

benchmark-matmult: examples/benchmark/benchmark-matmult.cpp build-info.o ggml.o $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

run-benchmark-matmult: benchmark-matmult
	./$@

.PHONY: run-benchmark-matmult swift

vdot: pocs/vdot/vdot.cpp ggml.o $(OBJS)
	$(CXX) $(CXXFLAGS) $^ -o $@ $(LDFLAGS)

q8dot: pocs/vdot/q8dot.cpp ggml.o $(OBJS)
	$(CXX) $(CXXFLAGS) $^ -o $@ $(LDFLAGS)

tests/test-llama-grammar: tests/test-llama-grammar.cpp ggml.o $(COMMON_DEPS) grammar-parser.o $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

tests/test-grammar-parser: tests/test-grammar-parser.cpp ggml.o llama.o $(COMMON_DEPS) grammar-parser.o $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

tests/test-double-float: tests/test-double-float.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

tests/test-grad0: tests/test-grad0.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

tests/test-opt: tests/test-opt.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

tests/test-quantize-fns: tests/test-quantize-fns.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

tests/test-quantize-perf: tests/test-quantize-perf.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

tests/test-sampling: tests/test-sampling.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

tests/test-tokenizer-0-falcon: tests/test-tokenizer-0-falcon.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

tests/test-tokenizer-0-llama: tests/test-tokenizer-0-llama.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

tests/test-tokenizer-1-bpe: tests/test-tokenizer-1-bpe.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

tests/test-tokenizer-1-llama: tests/test-tokenizer-1-llama.cpp ggml.o llama.o $(COMMON_DEPS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(filter-out %.h,$^) -o $@ $(LDFLAGS)

tests/test-c.o: tests/test-c.c llama.h
	$(CC) $(CFLAGS) -c $(filter-out %.h,$^) -o $@
