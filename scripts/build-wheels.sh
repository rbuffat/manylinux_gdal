#!/bin/bash
set -e -u -x

function repair_wheel {
    wheel="$1"
    if ! auditwheel show "$wheel"; then
        echo "Skipping non-platform wheel $wheel"
    else
        auditwheel show "$wheel"
        auditwheel repair "$wheel" --plat "manylinux_2_24_x86_64" -w /wheelhouse/
    fi
}


for PY in cp36 cp37 cp38 cp39 cp310; do

    for PYBIN in /opt/python/${PY}*/bin; do
        echo "${PYBIN}"
        "${PYBIN}/python" -m pip install -r /io/build-deps.txt
        mkdir -p /wheelhouse/${PY}
        "${PYBIN}/python" -m pip wheel /app --no-deps -w /wheelhouse/${PY}
    done

    # Bundle external shared libraries into the wheels
    for whl in /wheelhouse/${PY}/*.whl; do
        repair_wheel "$whl"
    done
done