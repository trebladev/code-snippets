import os
import numpy as np

def parse(qargs, results):
    result_np = []
    for line in results[1:]:
        result_np.append([''.join(filter(str.isdigit, word)) for word in line.split(',')])
    result_np = np.array(result_np)

    return result_np


def query_gpu():
    # qargs = ['index', 'memory.free', 'memory.total']
    qargs = ['index', 'memory.used', 'memory.total']
    cmd = 'nvidia-smi --query-gpu={} --format=csv,noheader'.format(','.join(qargs))
    results = os.popen(cmd).readlines()

    # return parse(qargs, results), results[0].strip()
    # return parse(qargs, results)
    return results

print(query_gpu())
