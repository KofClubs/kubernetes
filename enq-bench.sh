#!/usr/bin/bash

# Ref https://gist.github.com/Huang-Wei/1d1d16ec0de0d23ce8ed2a2448a44c4d
# Prepare two branches <old> and <new>, both with your benchmark test yaml located
# at scheduler_perf/config/performance-config.yaml
# <new> branch should contain the EventsToRegister() implementation for your plugin.
# <old> is master at 0486f1a728c964f643c70d1f3aea59243a4fedf8
# <new> is implement-EventsToRegister-nodeports (at 2678f269447c3e84448f3225f7b9584e68f5186d)

for br in test#100004-old test#100004-new; do
  git checkout $br
  # Run the test 10 times.
  for i in {1..10}; do
    # <1000 5000> may need to be tweaked depending on your benchmark test name.
    for nodes in 1000 5000; do
      echo "====$i-${nodes}Nodes===="
      # Note: you need to replace SchedulingWithPodChurn/${nodes}Nodes with your
      # corresponding (sub)benchmark test name.
      make test-integration WHAT=./test/integration/scheduler_perf KUBE_TEST_VMODULE="''" KUBE_TEST_ARGS="-alsologtostderr=true -logtostderr=true -run=^$$ -benchtime=1ns -bench=BenchmarkPerfScheduling/SchedulingWithPortsUnsatisfied/${nodes}Nodes -data-items-dir ~/logs/${br}/${nodes}Nodes"
      sleep 5
    done
  done
done

# After the above completes, it's expected to get a bunch of Benchmark*.json
# located at ~/logs/{old|new}/{1000|5000}.
# Next, let's concat them into a single file
for folder in ~/logs/test#100004-old/1000Nodes ~/logs/test#100004-old/5000Nodes ~/logs/test#100004-new/1000Nodes ~/logs/test#100004-new/5000Nodes; do
  ls $folder/BenchmarkPerfScheduling* | while read f; do
    echo "====$f===="
    cat $f >> $folder/result.txt
    echo "" >> $folder/result.txt
  done
done

# If you see a lot of timeout issues and hence cannot get desired results (a lot of 
# BenchmarkPerfScheduling*.json gets a single line with null result).
# Try to rebase #96696 to work it around.

# Next, you should be able to compare ~/logs/old/{1000|5000}/result.txt with
# ~/logs/new/{1000|5000}/result.txt
# You can leverage https://github.com/Huang-Wei/k8s-sched-perf-stat to get the diff in one command.