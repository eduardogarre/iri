import std.conv;
import std.stdio;
import std.string;

import apoyo;
import arbol;
static import interprete;
static import lexico;
static import semantico;
static import sintaxis;

dstring archivo = "código.ri";

void main()
{
	CHARLATÁN = true;
	INFO = true;

	dstring código_ri = leearchivo(archivo);

	iri(código_ri);
}

void iri(dstring código)
{

	lexema[] resultado_lex = lexico.analiza(código);

	charlatánln();

	foreach(lex; resultado_lex)
	{
		charlatánln(to!dstring(lex));
	}

	charlatánln();
	charlatánln();

	Nodo árbol_gramatical = sintaxis.analiza(resultado_lex);

	charlatánln();

	Nodo árbol_semántico = semantico.analiza(árbol_gramatical);

	charlatánln();

	bool resultado = interprete.analiza(árbol_semántico);
}