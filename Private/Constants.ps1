$script:ERROR_CODES = @{
    'W291' = 'Trailing whitespace'
    'F541' = 'F-string issues'
    'E722' = 'Bare except'
    'E402' = 'Import not at top'
    'C901' = 'Complexity'
}

$script:defaultConfig = @{
    MaxLineLength = 120
    MaxComplexity = 10
    LogFormat = "'%(path)s||%(row)d||%(col)d|| %(code)s %(text)s'"
}

$script:REQUIRED_PACKAGES = @(
    'flake8',
    'black',
    'autopep8',
    'autoflake',
    'add-trailing-comma'
)