enum AppFlavor {
  dev('DEV'),
  stg('STG'),
  uat('UAT'),
  prod('PROD');

  const AppFlavor(this.label);

  final String label;
}
