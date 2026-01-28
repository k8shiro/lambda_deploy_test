from importlib.metadata import distributions

for d in distributions():
    print(f'{d.metadata["Name"]}=={d.version}')
