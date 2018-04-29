@echo OFF

echo aritmética: sum, res, mul, div
.\iri.exe -s .\pruebas\op_sum.ri
.\iri.exe -s .\pruebas\op_res.ri
.\iri.exe -s .\pruebas\op_mul.ri
.\iri.exe -s .\pruebas\op_div.ri
echo.

echo funciones: recursión
.\iri.exe -s .\pruebas\func_factorial.ri
echo.

echo comparaciones: ig, dsig, ma, me, maig, meig
.\iri.exe -s .\pruebas\op_cmp_ig.ri
.\iri.exe -s .\pruebas\op_cmp_dsig.ri
.\iri.exe -s .\pruebas\op_cmp_ma.ri
.\iri.exe -s .\pruebas\op_cmp_me.ri
.\iri.exe -s .\pruebas\op_cmp_maig.ri
.\iri.exe -s .\pruebas\op_cmp_meig.ri
echo.

echo op:conv
echo.

echo op:slt
echo.

echo op:phi
echo.

echo op:rsrva
echo.

echo op:lee
echo.

echo op:guarda
echo.

echo op:leeval
echo.

echo op:ponval
echo.

echo op:ret
echo.