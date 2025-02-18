{ lib
, stdenv
, fetchurl
, removeReferencesTo
, cppSupport ? false
, fortranSupport ? false
, fortran
, zlibSupport ? true
, zlib
, szipSupport ? false
, szip
, mpiSupport ? false
, mpi
, enableShared ? !stdenv.hostPlatform.isStatic
, javaSupport ? false
, jdk
, usev110Api ? false
, threadsafe ? false
, python3
}:

# cpp and mpi options are mutually exclusive
# (--enable-unsupported could be used to force the build)
assert !cppSupport || !mpiSupport;

let inherit (lib) optional optionals; in

stdenv.mkDerivation rec {
  version = "1.14.0";
  pname = "hdf5"
    + lib.optionalString cppSupport "-cpp"
    + lib.optionalString fortranSupport "-fortran"
    + lib.optionalString mpiSupport "-mpi"
    + lib.optionalString threadsafe "-threadsafe";

  src = fetchurl {
    url = "https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${lib.versions.majorMinor version}/hdf5-${version}/src/hdf5-${version}.tar.bz2";
    sha256 = "sha256-5OeUM0UO2uKGWkxjKBiLtFORsp10+MU47mmfCxFsK6A=";
  };

  passthru = {
    inherit
      cppSupport
      fortranSupport
      fortran
      zlibSupport
      zlib
      szipSupport
      szip
      mpiSupport
      mpi
      ;
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [ removeReferencesTo ]
    ++ optional fortranSupport fortran;

  buildInputs = optional fortranSupport fortran
    ++ optional szipSupport szip
    ++ optional javaSupport jdk;

  propagatedBuildInputs = optional zlibSupport zlib
    ++ optional mpiSupport mpi;

  configureFlags = optional cppSupport "--enable-cxx"
    ++ optional fortranSupport "--enable-fortran"
    ++ optional szipSupport "--with-szlib=${szip}"
    ++ optionals mpiSupport [ "--enable-parallel" "CC=${mpi}/bin/mpicc" ]
    ++ optional enableShared "--enable-shared"
    ++ optional javaSupport "--enable-java"
    ++ optional usev110Api "--with-default-api-version=v110"
    # hdf5 hl (High Level) library is not considered stable with thread safety and should be disabled.
    ++ optionals threadsafe [ "--enable-threadsafe" "--disable-hl" ];

  patches = [
    # Avoid non-determinism in autoconf build system:
    # - build time
    # - build user
    # - uname -a (kernel version)
    # Can be dropped once/if we switch to cmake.
    ./hdf5-more-determinism.patch
  ];

  postInstall = ''
    find "$out" -type f -exec remove-references-to -t ${stdenv.cc} '{}' +
    moveToOutput 'bin/h5cc' "''${!outputDev}"
    moveToOutput 'bin/h5c++' "''${!outputDev}"
    moveToOutput 'bin/h5fc' "''${!outputDev}"
    moveToOutput 'bin/h5pcc' "''${!outputDev}"
  '';

  # Remove reference to /build, which get introduced
  # into AM_CPPFLAGS since hdf5-1.14.0. Cmake of various
  # packages using HDF5 gets confused trying access the non-existent path.
  postFixup = ''
    for i in h5cc h5pcc h5c++; do
      if [ -f $dev/bin/$i ]; then
        substituteInPlace $dev/bin/$i --replace \
          '-I/build/hdf5-${version}/src/H5FDsubfiling' ""
      fi
    done
  '';

  enableParallelBuilding = true;

  passthru.tests = {
    inherit (python3.pkgs) h5py;
  };

  meta = with lib; {
    description = "Data model, library, and file format for storing and managing data";
    longDescription = ''
      HDF5 supports an unlimited variety of datatypes, and is designed for flexible and efficient
      I/O and for high volume and complex data. HDF5 is portable and is extensible, allowing
      applications to evolve in their use of HDF5. The HDF5 Technology suite includes tools and
      applications for managing, manipulating, viewing, and analyzing data in the HDF5 format.
    '';
    license = licenses.bsd3; # Lawrence Berkeley National Labs BSD 3-Clause variant
    maintainers = [ maintainers.markuskowa ];
    homepage = "https://www.hdfgroup.org/HDF5/";
    platforms = platforms.unix;
  };
}
