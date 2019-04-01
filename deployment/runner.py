import json
import shlex
import subprocess

def run(command, check=False):
    print(f'Executing command: {command}\n')
    split_command = shlex.split(command)
    proc = subprocess.run(split_command, check, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout = decode_stream(proc.stdout)
    stderr = decode_stream(proc.stderr)
    print(stdout)
    if stderr is not None:
        print('ERROR:')
        print(stderr)

    if check and proc.returncode != 0:
        raise subprocess.CalledProcessError(return_code, command, stdout, stderr)

    return stdout, proc

def decode_stream(stream):
    return stream.strip().decode("utf-8") if stream else None

def get_json(stream):
    res = decode_stream(stream)
    return json.loads(res)
