import apoyo;
import arbol;
import docopt;
static import interprete;
static import lexico;
static import semantico;
static import sintaxis;
import std.conv;
import std.stdio;
import std.string;

int main(string[] args)
{
	auto doc = "iri - Interprete de Representacion Intermedia.

Usage:
   iri [-i | -c | -s] <archivo>
   iri (-v | --version)
   iri (-a | --ayuda)

Options:
   -a --ayuda         Muestra esta pantalla.
   -v --version       Muestra la version.
   -s --sin-avisos	  Silencioso. Desactiva los avisos durante la compilación.
   -i --info          Opcion 'habladora'.
   -c --charlatan     Opcion 'verborreica', MUY habladora.

Argumentos:
   <archivo>          El archivo a interpretar.
";

	auto argumentos = docopt.docopt(doc, args[1..$], false, "iri 0.1a");

	if(argumentos["--version"].isTrue())
	{
		return 0;
	}

	if(argumentos["--info"].isTrue())
	{
		INFO = true;
	}

	if(argumentos["--sin-avisos"].isTrue())
	{
		AVISO = false;
	}

	if(argumentos["--charlatan"].isTrue())
	{
		INFO = true;
		CHARLATÁN = true;
	}

	if(argumentos["--ayuda"].isTrue())
	{
		writeln(doc);
		return 0;
	}

	string a = argumentos["<archivo>"].value().toString;
	archivo = to!dstring(a);

	dstring código_ri = leearchivo(archivo);

	iri(código_ri);

	return 0;
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

	Literal resultado = interprete.analiza(árbol_semántico);
}