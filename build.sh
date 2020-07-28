#!/bin/bash
set -x
set -e
set -v

FLINK_URL="FLINK-1.10.1-bin-scala_2.11.tgz"
FLINK_VERSION="1.10.1"
EXTENS_VERSION="BIN-SCALA_2.11"
OS_VERSION="7"

flink_service_name="FLINK"
flink_service_name_lower="$( echo $flink_service_name | tr '[:upper:]' '[:lower:]' )"
flink_archive="$( basename $FLINK_URL )"
flink_unzip_folder="${flink_service_name_lower}-${FLINK_VERSION}"
flink_folder_lower="$( basename $flink_archive .tgz )"
flink_parcel_folder="$( echo $flink_folder_lower | tr '[:lower:]' '[:upper:]')"
flink_parcel_name="$flink_parcel_folder-el${OS_VERSION}.parcel"
flink_built_folder="${flink_parcel_folder}_build"
flink_csd_build_folder="flink-csd-src"



function build_flink_parcel {
  if [ -f "$flink_built_folder/$flink_parcel_name" ] && [ -f "$flink_built_folder/manifest.json" ]; then
    return
  fi
  if [ ! -d $flink_parcel_folder ]; then
    tar -zxvf $flink_archive
    mkdir -p $flink_parcel_folder/lib
    sleep 3
    echo ${flink_unzip_folder}
    mv ${flink_unzip_folder}  ${flink_parcel_folder}/lib/${flink_service_name_lower}
  fi
  cp -r flink-parcel-src/meta $flink_parcel_folder/
  chmod 755 flink-parcel-src/flink*
  cp -r flink-parcel-src/flink-master.sh ${flink_parcel_folder}/lib/${flink_service_name_lower}/bin/
  cp -r flink-parcel-src/flink-worker.sh ${flink_parcel_folder}/lib/${flink_service_name_lower}/bin/
  cp -r flink-parcel-src/flink-yarn.sh ${flink_parcel_folder}/lib/${flink_service_name_lower}/bin/
  java -jar /root/cm_ext/validator/target/validator.jar -d ./$flink_parcel_folder
  mkdir -p $flink_built_folder
  tar zcvhf ./$flink_built_folder/$flink_parcel_name $flink_parcel_folder --owner=root --group=root
  java -jar /root/cm_ext/validator/target/validator.jar -f ./$flink_built_folder/$flink_parcel_name
  python /root/cm_ext/make_manifest/make_manifest.py ./$flink_built_folder
  sha1sum ./$flink_built_folder/$flink_parcel_name |awk '{print $1}' > ./$flink_built_folder/${flink_parcel_name}.sha
}

function build_flink_csd_on_yarn {
  JARNAME=${flink_service_name}_ON_YARN-${FLINK_VERSION}.jar
  if [ -f "$JARNAME" ]; then
    return
  fi
  java -jar /root/cm_ext/validator/target/validator.jar -s ${flink_csd_build_folder}/descriptor/service.sdl -l "SPARK_ON_YARN SPARK2_ON_YARN"
  jar -cvf ./$JARNAME -C ${flink_csd_build_folder} .
}


case $1 in
parcel)
  build_flink_parcel
  ;;
csd_on_yarn)
  build_flink_csd_on_yarn
  ;;
*)
  echo "Usage: $0 [parcel|csd_on_yarn]"
  ;;
esac


