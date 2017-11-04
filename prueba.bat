@echo OFF

echo op:sum
.\iri.exe .\pruebas\op_sum.ri
echo.

echo op:res
.\iri.exe .\pruebas\op_res.ri
echo.

echo op:mul
.\iri.exe .\pruebas\op_mul.ri
echo.

echo op:div
.\iri.exe .\pruebas\op_div.ri
echo.

echo op:llama
echo.

echo op:cmp
.\iri.exe .\pruebas\op_cmp_ig.ri
echo.
.\iri.exe .\pruebas\op_cmp_dsig.ri
echo.
.\iri.exe .\pruebas\op_cmp_ma.ri
echo.
.\iri.exe .\pruebas\op_cmp_me.ri
echo.
.\iri.exe .\pruebas\op_cmp_maig.ri
echo.
.\iri.exe .\pruebas\op_cmp_meig.ri
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