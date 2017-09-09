module arbol;

import std.conv;
import std.stdint; // uint64_t y demás tipos
import std.stdio;

enum Categoría
{
    TIPO,
    NÚMERO,
    TEXTO,
    LITERAL,
    IDENTIFICADOR,
    
    DEFINE_IDENTIFICADOR,
    IDENTIFICADOR_EXTERNO,

    OPERACIÓN,
    ASIGNACIÓN,

    AFIRMACIÓN,

    BLOQUE,

    ARGUMENTO,
    ARGUMENTOS,

    DEFINE_FUNCIÓN,
    DECLARA_FUNCIÓN,

    OBJETO
}

class Nodo
{
    Categoría categoría;
    dstring     dato = "";
    Nodo[]      ramas;
    uint64_t    línea;

    this()
    {

    }
}

class Literal : Nodo
{
    dstring tipo;

    this()
    {
        super();
        this.categoría = Categoría.LITERAL;
    }
}

class Identificador : Nodo
{
    dstring nombre;
    
    this()
    {
        super();
        this.categoría = Categoría.IDENTIFICADOR;
    }
}

class Operación : Nodo
{
    this()
    {
        super();
        this.categoría = Categoría.OPERACIÓN;
    }
}

class Asignación : Nodo
{
    this()
    {
        super();
        this.categoría = Categoría.ASIGNACIÓN;
    }
}

class DefineIdentificador : Nodo
{
    dstring ámbito  = "";
    dstring tipo    = "";
    dstring nombre  = "";

    this()
    {
        super();
        this.categoría = Categoría.DEFINE_IDENTIFICADOR;
    }
}

class IdentificadorExterno : Nodo
{
    dstring ámbito  = "externo";
    dstring tipo    = "";
    dstring nombre  = "";

    this()
    {
        super();
        this.categoría = Categoría.IDENTIFICADOR_EXTERNO;
    }
}

class Bloque : Nodo
{
    this()
    {
        super();
        this.categoría = Categoría.BLOQUE;
    }
}

class Argumentos : Nodo
{
    this()
    {
        super();
        this.categoría = Categoría.ARGUMENTOS;
    }
}

class Argumento : Nodo
{
    dstring tipo;
    dstring nombre;

    this()
    {
        super();
        this.categoría = Categoría.ARGUMENTO;
    }
}

class DefineFunción : Nodo
{
    dstring retorno;
    dstring nombre;

    this()
    {
        super();
        this.categoría = Categoría.DEFINE_FUNCIÓN;
    }
}

class DeclaraFunción : Nodo
{
    dstring retorno;
    dstring nombre;

    this()
    {
        super();
        this.categoría = Categoría.DECLARA_FUNCIÓN;
    }
}

class Objeto : Nodo
{
    dstring nombre = "";

    this()
    {
        super();
        this.categoría = Categoría.OBJETO;
    }
}

uint profundidad_árbol = 0;

void recorre_árbol_gramatical(Nodo n)
{
    profundidad_árbol++;

    if(n)
    {
        for(int i = 1; i < profundidad_árbol; i++)
        {
            write("   ");
        }
        write("[hijos:");
        write(n.ramas.length);
        write("] ");
        imprime_nodo_gramatical(n);

        int i;
        for(i = 0; i < n.ramas.length; i++)
        {
            recorre_árbol_gramatical(n.ramas[i]);
        }
    }

    profundidad_árbol--;
}

void imprime_nodo_gramatical(Nodo n)
{
    switch(n.categoría)
    {
        case Categoría.LITERAL:
            auto l = cast(Literal)n;
            write(l.categoría);
            write(" [tipo:");
            write(l.tipo);
            write("] [dato:");
            write(l.dato);
            write("] [línea:");
            write(l.línea);
            write("]");
            writeln();
            break;

        case Categoría.IDENTIFICADOR:
            auto l = cast(Identificador)n;
            write(l.categoría);
            write(" [id:");
            write(l.dato);
            write("] [línea:");
            write(l.línea);
            write("]");
            writeln();
            break;

        case Categoría.OPERACIÓN:
            auto o = cast(Operación)n;
            write(o.categoría);
            write(" [op:");
            write(o.dato);
            write("] [línea:");
            write(o.línea);
            write("]");
            writeln();
            break;

        case Categoría.ASIGNACIÓN:
            auto a = cast(Asignación)n;
            write(a.categoría);
            write(" [línea:");
            write(a.línea);
            write("]");
            writeln();
            break;

        case Categoría.DEFINE_IDENTIFICADOR:
            auto did = cast(DefineIdentificador)n;
            write(did.categoría);
            write(" [ámbito:");
            write(did.ámbito);
            write("] [tipo:");
            write(did.tipo);
            write("] [nombre:");
            write(did.nombre);
            write("] [línea:");
            write(did.línea);
            write("]");
            writeln();
            break;

        case Categoría.IDENTIFICADOR_EXTERNO:
            auto idex = cast(IdentificadorExterno)n;
            write(idex.categoría);
            write(" [ámbito:");
            write(idex.ámbito);
            write("] [tipo:");
            write(idex.tipo);
            write("] [nombre:");
            write(idex.nombre);
            write("] [línea:");
            write(idex.línea);
            write("]");
            writeln();
            break;

        case Categoría.BLOQUE:
            auto b = cast(Bloque)n;
            write(b.categoría);
            write(" [línea:");
            write(b.línea);
            write("]");
            writeln();
            break;

        case Categoría.ARGUMENTOS:
            auto a = cast(Argumentos)n;
            write(a.categoría);
            write(" [línea:");
            write(a.línea);
            write("]");
            writeln();
            break;

        case Categoría.ARGUMENTO:
            auto a = cast(Argumento)n;
            write(a.categoría);
            write(" [tipo:");
            write(a.tipo);
            write("] [nombre:");
            write(a.nombre);
            write("] [línea:");
            write(a.línea);
            write("]");
            writeln();
            break;

        case Categoría.DEFINE_FUNCIÓN:
            auto df = cast(DefineFunción)n;
            write(df.categoría);
            write(" [ret:");
            write(df.retorno);
            write("] [nombre:");
            write(df.nombre);
            write("] [línea:");
            write(df.línea);
            write("]");
            writeln();
            break;

        case Categoría.DECLARA_FUNCIÓN:
            auto df = cast(DeclaraFunción)n;
            write(df.categoría);
            write(" [ret:");
            write(df.retorno);
            write("] [nombre:");
            write(df.nombre);
            write("] [línea:");
            write(df.línea);
            write("]");
            writeln();
            break;

        case Categoría.OBJETO:
            auto obj = cast(Objeto)n;
            write(obj.categoría);
            write(" [nombre:");
            write(obj.nombre);
            write("] [línea:");
            write(obj.línea);
            write("]");
            writeln();
            break;

        default: break;
    }
}