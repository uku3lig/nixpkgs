{
  lib,
  buildPythonPackage,
  fetchPypi,
  google-api-core,
  grpc-google-iam-v1,
  mock,
  proto-plus,
  protobuf,
  pytest-asyncio,
  pytestCheckHook,
  pythonOlder,
  setuptools,
}:

buildPythonPackage rec {
  pname = "google-cloud-iam-logging";
  version = "1.4.2";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    pname = "google_cloud_iam_logging";
    inherit version;
    hash = "sha256-2tpXDDqP6JN9y8wqku/C3+I9ymns5EfxvfR5eeTDstU=";
  };

  build-system = [ setuptools ];

  dependencies = [
    google-api-core
    grpc-google-iam-v1
    proto-plus
    protobuf
  ] ++ google-api-core.optional-dependencies.grpc;

  nativeCheckInputs = [
    mock
    pytestCheckHook
    pytest-asyncio
  ];

  pythonImportsCheck = [
    "google.cloud.iam_logging"
    "google.cloud.iam_logging_v1"
  ];

  meta = with lib; {
    description = "IAM Service Logging client library";
    homepage = "https://github.com/googleapis/google-cloud-python/tree/main/packages/google-cloud-iam-logging";
    changelog = "https://github.com/googleapis/google-cloud-python/blob/google-cloud-iam-logging-v${version}/packages/google-cloud-iam-logging/CHANGELOG.md";
    license = licenses.asl20;
    maintainers = with maintainers; [ fab ];
  };
}
