#!/usr/bin/env python3.7

import os

from runner import run, decode_stream, get_json

image_name = "sinatra-hello"
profile = "profile-ap-south-1"
region = "ap-south-1"

def prompt(command, check=True):
    print(f'Executing: {command}')
    res = input("Proceed(yes/no/skip)? ")
    if res.startswith('y'):
        return run(command, check)
    elif res.startswith('n'):
        exit(0)
    else:
        return 'skip', 'skip'


print("#1: Pull the image from remote repo...")
print("--------------------------------------")
prompt(f'docker pull onlydevelop/{image_name}')


print("#2: Login to the ECR...")
print("--------------------------------")
login_command, _ = prompt(f'aws ecr get-login --no-include-email --profile {profile} --region {region}')
if login_command != 'skip':
    run(login_command, True)


print("#3: Create ECR repo if not exists...")
print("------------------------------------")
ecr_repo = image_name
stdout, proc = prompt(f'aws ecr describe-repositories --repository-names {ecr_repo} --profile {profile} --region {region}', False)

if stdout is None:
    print(f'Creating ECR Repo {ecr_repo}...')
    prompt(f'aws ecr create-repository --repository-name {ecr_repo} --profile {profile} --region {region}', False)
elif stdout != 'skip':
    print(f'ECR Repo {ecr_repo} exists...')


print("#4: Tag the image for ECR repo...")
print("------------------------------------")
stdout, proc = run(f'aws ecr describe-repositories --repository-names {ecr_repo} --profile {profile} --region {region}', False)
json_obj = get_json(proc.stdout)
repo_uri = json_obj['repositories'][0]['repositoryUri']
stdout, proc = prompt(f'docker tag {image_name}:latest {repo_uri}', False)


print("#5: Upload the image to ECR repo...")
print("-----------------------------------")
prompt(f'docker push {repo_uri}')


print("#6: Create the task definition in ECS...")
print("----------------------------------------")
current_dir = os.path.dirname(os.path.abspath(__file__))
prompt(f'aws ecs register-task-definition --profile {profile} --region {region} --cli-input-json file://{current_dir}/task_definition.json', True)
if stdout != 'skip':
    _, proc = run(f'aws ecs list-task-definitions --profile {profile} --region {region} --family-prefix {image_name}', False)
    json_obj = get_json(proc.stdout)
    task_def_arns = json_obj['taskDefinitionArns']
    latest = 1
    for task_def_arn in task_def_arns:
        version = int(task_def_arn.split(":")[-1])
        if version > latest:
            latest = version
    print("latest: ", latest)
