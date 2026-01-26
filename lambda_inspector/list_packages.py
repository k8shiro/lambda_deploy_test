import pkg_resources

for d in pkg_resources.working_set:
    print(f'{d.project_name}=={d.version}')
