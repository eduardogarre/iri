import std.stdio;
import std.string;

import apoyo;
import arbol;
static import lexico;
static import sintaxis;

dstring archivo = "código.ri";

void main()
{
	INFO = false;

	dstring código_ri = leearchivo(archivo);

	iri(código_ri);
}

void iri(dstring código)
{

	lexema[] resultado_lex = lexico.analiza(código);

	writeln();

	writeln(resultado_lex);

	Nodo árbol_sintaxis_abstracta = sintaxis.analiza(resultado_lex);

	writeln();

	recorre_árbol(árbol_sintaxis_abstracta);

	writeln();
}