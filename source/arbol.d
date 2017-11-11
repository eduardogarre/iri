module arbol;

import std.conv;
import std.stdint; // uint64_t y demás tipos
import std.stdio;

enum Categoría
{
    RESERVADA,
    TIPO,
    NÚMERO,
    CARÁCTER,
    LITERAL,
    IDENTIFICADOR,

    ETIQUETA,
    
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
    dstring     etiqueta;

    this()
    {

    }
}

class Etiqueta : Nodo
{
    this()
    {
        super();
        this.categoría = Categoría.ETIQUETA;
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
    bool vector;
    bool estructura;
    dstring tipo;
    dstring elementos;

    this()
    {
        super();
        this.categoría = Categoría.TIPO;
    }
}

class Literal : Nodo
{
    dstring tipo;
    bool vector;
    bool estructura;

    this()
    {
        super();
        this.categoría = Categoría.LITERAL;
    }

    Literal dup()
    {
        Literal l = new Literal();
        
        l.dato = this.dato;
        l.tipo = this.tipo;
        l.vector = this.vector;
        l.estructura = this.estructura;
        l.ramas = this.ramas.dup();
        l.línea = this.línea;
        l.etiqueta = this.etiqueta;

        return l;
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

class DefineIdentificadorGlobal : Nodo
{
    dstring ámbito  = "";
    dstring nombre  = "";
    Tipo tipo;

    this()
    {
        super();
        this.categoría = Categoría.DEFINE_IDENTIFICADOR_GLOBAL;
    }
}

class DeclaraIdentificadorGlobal : Nodo
{
    dstring ámbito  = "";
    dstring nombre  = "";
    Tipo tipo;

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
    dstring nombre;
    Tipo tipo;

    this()
    {
        super();
        this.categoría = Categoría.ARGUMENTO;
    }
}

class DefineFunción : Nodo
{
    Tipo retorno;
    dstring nombre;

    this()
    {
        super();
        this.categoría = Categoría.DEFINE_FUNCIÓN;
    }
}

class DeclaraFunción : Nodo
{
    Tipo retorno;
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