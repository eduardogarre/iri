#!/bin/sh

echo Pruebas de IRI
echo ""
echo aritmética: sum, res, mul, div
./iri -s ./pruebas/op_sum.ri
./iri -s ./pruebas/op_res.ri
./iri -s ./pruebas/op_mul.ri
./iri -s ./pruebas/op_div.ri
echo ""
echo funciones: recursión
./iri -s ./pruebas/func_factorial.ri
echo ""
echo comparaciones: ig, dsig, ma, me, maig, meig
./iri -s ./pruebas/op_cmp_ig.ri
./iri -s ./pruebas/op_cmp_dsig.ri
./iri -s ./pruebas/op_cmp_ma.ri
./iri -s ./pruebas/op_cmp_me.ri
./iri -s ./pruebas/op_cmp_maig.ri
./iri -s ./pruebas/op_cmp_meig.ri
echo ""
