{ lib
, buildPythonPackage
, fetchPypi
, httpx
, pythonOlder
, zeep
}:

buildPythonPackage rec {
  pname = "onvif-zeep-async";
  version = "2.1.4";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-F8NqdEYz38mWSfOQ9oIjQccaGkON8skqm+ItQD71CPo=";
  };

  propagatedBuildInputs = [
    httpx
    zeep
  ];

  pythonImportsCheck = [
    "onvif"
  ];

  # Tests are not shipped
  doCheck = false;

  meta = with lib; {
    description = "ONVIF Client Implementation in Python";
    homepage = "https://github.com/hunterjm/python-onvif-zeep-async";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ fab ];
  };
}
