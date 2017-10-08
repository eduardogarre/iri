module arbol;

import std.conv;
import std.stdint; // uint64_t y demás tipos
import std.stdio;

enum Categoría
{
    RESERVADA,
    TIPO,
    NÚMERO,
    TEXTO,
    LITERAL,
    IDENTIFICADOR,
    
    DECLARA_IDENTIFICADOR_GLOBAL,
    DEFINE_IDENTIFICADOR_GLOBAL,
    DEFINE_IDENTIFICADOR_LOCAL,

    OPERACIÓN,
    LLAMA_FUNCIÓN,
    ASIGNACIÓN,

    AFIRMACIÓN,

    BLOQUE,

    ARGUMENTO,
    ARGUMENTOS,

    DEFINE_FUNCIÓN,
    DECLARA_FUNCIÓN,

    MÓDULO
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

class Reservada : Nodo
{
    this()
    {
        super();
        this.categoría = Categoría.RESERVADA;
    }
}

class Tipo : Nodo
{
    dstring tipo;

    this()
    {
        super();
        this.categoría = Categoría.TIPO;
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

class LlamaFunción : Nodo
{
    dstring nombre;
    dstring tipo;

    this()
    {
        super();
        this.categoría = Categoría.LLAMA_FUNCIÓN;
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

class DefineIdentificadorLocal : Nodo
{
    dstring ámbito  = "";
    dstring tipo    = "";
    dstring nombre  = "";

    this()
    {
        super();
        this.categoría = Categoría.DEFINE_IDENTIFICADOR_LOCAL;
    }
}

class DefineIdentificadorGlobal : Nodo
{
    dstring ámbito  = "";
    dstring tipo    = "";
    dstring nombre  = "";

    this()
    {
        super();
        this.categoría = Categoría.DEFINE_IDENTIFICADOR_GLOBAL;
    }
}

class DeclaraIdentificadorGlobal : Nodo
{
    dstring ámbito  = "";
    dstring tipo    = "";
    dstring nombre  = "";

    this()
    {
        super();
        this.categoría = Categoría.DECLARA_IDENTIFICADOR_GLOBAL;
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

class Módulo : Nodo
{
    dstring nombre = "";

    this()
    {
        super();
        this.categoría = Categoría.MÓDULO;
    }
}