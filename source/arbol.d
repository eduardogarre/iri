module arbol;

dstring módulo = "Árbol.d";

import apoyo;
import semantico;
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
    Tipo tipo;
    bool vector;
    bool estructura;

    this()
    {
        super();
        this.categoría = Categoría.LITERAL;
        tipo = new Tipo();
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
    Tipo retorno;

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

bool compara_nodos(Nodo* n, Nodo* m)
{
    if(*n && *m)
    {
        // Comprobaciones de la categoría base, "Nodo"
        if(n.categoría != m.categoría)
        {
            aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
             ~ "Nodo1.categoría y Nodo2.categoría no coinciden:\n["
             ~ to!dstring(n.categoría) ~ "] vs ["
             ~ to!dstring(m.categoría) ~ "]");

            return false;
        }
        else if(n.dato != m.dato)
        {
            aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
             ~ "Nodo1.dato y Nodo2.dato no coinciden:\n["
             ~ to!dstring(n.dato) ~ "] vs ["
             ~ to!dstring(m.dato) ~ "]");

            return false;
        }
        else if(n.ramas.length != m.ramas.length)
        {
            aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
             ~ "Nodo1.ramas.length y Nodo2.ramas.length no coinciden:\n["
             ~ to!dstring(n.ramas.length) ~ "] vs ["
             ~ to!dstring(m.ramas.length) ~ "]");

            return false;
        }

        // Comprobaciones específicas de cada categoría
        switch(n.categoría)
        {
            case Categoría.ETIQUETA:
                // El nodo "Etiqueta" no requiere comprobaciones especiales
                break;

            case Categoría.TIPO:
                auto t1 = cast(Tipo)(*n);
                auto t2 = cast(Tipo)(*m);
                // El nodo "Tipo" tiene las siguientes variables:
                // t.vector, .estructura, .tipo, .elementos
                if(t1.vector != t2.vector)
                {
                    aborta(módulo, t1.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "Tipo.vector y Tipo.vector no coinciden:\n["
                    ~ to!dstring(t1.vector) ~ "] vs ["
                    ~ to!dstring(t2.vector) ~ "]");

                    return false;
                }
                else if(t1.estructura != t2.estructura)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "Tipo.estructura y Tipo.estructura no coinciden:\n["
                    ~ to!dstring(t1.estructura) ~ "] vs ["
                    ~ to!dstring(t2.estructura) ~ "]");

                    return false;
                }
                else if(t1.tipo != t2.tipo)
                {
                    aborta(módulo, n.línea, "Estos 2 tipos no coinciden: ["
                    ~ to!dstring(t1.tipo) ~ "] vs ["
                    ~ to!dstring(t2.tipo) ~ "]");

                    return false;
                }
                else if(t1.elementos != t2.elementos)
                {
                    avisa(módulo, n.línea, "Estos 2 tipos tienen tamaños distintos: ["
                    ~ to!dstring(t1.elementos) ~ "] vs ["
                    ~ to!dstring(t2.elementos) ~ "]");

                    //return true;
                }
                break;

            case Categoría.RESERVADA:
                // El nodo "Reservada" no requiere comprobaciones especiales
                break;

            case Categoría.LITERAL:
                auto l1 = cast(Literal)(*n);
                auto l2 = cast(Literal)(*m);
                // El nodo "Literal" tiene las siguientes variables:
                // l.vector, .estructura, .tipo
                if(l1.vector != l2.vector)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "Literal.vector y Literal.vector no coinciden:\n["
                    ~ to!dstring(l1.vector) ~ "] vs ["
                    ~ to!dstring(l2.vector) ~ "]");

                    return false;
                }
                else if(l1.estructura != l2.estructura)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "Literal.estructura y Literal.estructura no coinciden:\n["
                    ~ to!dstring(l1.estructura) ~ "] vs ["
                    ~ to!dstring(l2.estructura) ~ "]");

                    return false;
                }
                else if(!compara_árboles(cast(Nodo *)(&(l1.tipo)), cast(Nodo *)(&(l2.tipo))))
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "Literal.tipo y Literal.tipo no coinciden:\n["
                    ~ to!dstring(l1.tipo) ~ "] vs ["
                    ~ to!dstring(l2.tipo) ~ "]");

                    return false;
                }
                break;

            case Categoría.IDENTIFICADOR:
                auto i1 = cast(Identificador)(*n);
                auto i2 = cast(Identificador)(*m);
                // El nodo "Identificador" tiene las siguientes variables:
                // i.nombre
                if(i1.nombre != i2.nombre)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "Identificador.nombre y Identificador.nombre no coinciden:\n["
                    ~ to!dstring(i1.nombre) ~ "] vs ["
                    ~ to!dstring(i1.nombre) ~ "]");

                    return false;
                }
                break;

            case Categoría.LLAMA_FUNCIÓN:
                auto l1 = cast(LlamaFunción)(*n);
                auto l2 = cast(LlamaFunción)(*m);
                // El nodo "LlamaFunción" tiene las siguientes variables:
                // l.nombre, .retorno
                if(l1.nombre != l2.nombre)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "LlamaFunción.nombre y LlamaFunción.nombre no coinciden:\n["
                    ~ to!dstring(l1.nombre) ~ "] vs ["
                    ~ to!dstring(l2.nombre) ~ "]");

                    return false;
                }
                else if(!compara_árboles(cast(Nodo *)(&(l1.retorno)), cast(Nodo *)(&(l2.retorno))))
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "LlamaFunción.tipo y LlamaFunción.tipo no coinciden:\n["
                    ~ to!dstring(l1.retorno) ~ "] vs ["
                    ~ to!dstring(l2.retorno) ~ "]");

                    return false;
                }
                break;

            case Categoría.OPERACIÓN:
                // El nodo "Operación" no requiere comprobaciones especiales
                break;

            case Categoría.ASIGNACIÓN:
                // El nodo "Asignación" no requiere comprobaciones especiales
                break;

            case Categoría.DEFINE_IDENTIFICADOR_GLOBAL:
                auto did1 = cast(DefineIdentificadorGlobal)(*n);
                auto did2 = cast(DefineIdentificadorGlobal)(*m);
                // El nodo "DefineIdentificadorGlobal" tiene las siguientes variables:
                // d.ámbito, .nombre, .tipo
                if(did1.ámbito != did2.ámbito)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "DefineIdentificadorGlobal.ámbito y DefineIdentificadorGlobal.ámbito no coinciden:\n["
                    ~ to!dstring(did1.ámbito) ~ "] vs ["
                    ~ to!dstring(did2.ámbito) ~ "]");

                    return false;
                }
                else if(did1.nombre != did2.nombre)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "DefineIdentificadorGlobal.nombre y DefineIdentificadorGlobal.nombre no coinciden:\n["
                    ~ to!dstring(did1.nombre) ~ "] vs ["
                    ~ to!dstring(did2.nombre) ~ "]");

                    return false;
                }
                else if(did1.tipo != did2.tipo)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "DefineIdentificadorGlobal.tipo y DefineIdentificadorGlobal.tipo no coinciden:\n["
                    ~ to!dstring(did1.tipo) ~ "] vs ["
                    ~ to!dstring(did2.tipo) ~ "]");

                    return false;
                }
                break;

            case Categoría.DECLARA_IDENTIFICADOR_GLOBAL:
                auto idex1 = cast(DeclaraIdentificadorGlobal)(*n);
                auto idex2 = cast(DeclaraIdentificadorGlobal)(*m);
                // El nodo "DeclaraIdentificadorGlobal" tiene las siguientes variables:
                // d.ámbito, .nombre, .tipo
                if(idex1.ámbito != idex2.ámbito)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "DeclaraIdentificadorGlobal.ámbito y DeclaraIdentificadorGlobal.ámbito no coinciden:\n["
                    ~ to!dstring(idex1.ámbito) ~ "] vs ["
                    ~ to!dstring(idex2.ámbito) ~ "]");

                    return false;
                }
                else if(idex1.nombre != idex2.nombre)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "DeclaraIdentificadorGlobal.nombre y DeclaraIdentificadorGlobal.nombre no coinciden:\n["
                    ~ to!dstring(idex1.nombre) ~ "] vs ["
                    ~ to!dstring(idex2.nombre) ~ "]");

                    return false;
                }
                else if(idex1.tipo != idex2.tipo)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "DeclaraIdentificadorGlobal.tipo y DeclaraIdentificadorGlobal.tipo no coinciden:\n["
                    ~ to!dstring(idex1.tipo) ~ "] vs ["
                    ~ to!dstring(idex2.tipo) ~ "]");

                    return false;
                }
                break;

            case Categoría.BLOQUE:
                // El nodo "Bloque" no requiere comprobaciones especiales
                break;

            case Categoría.ARGUMENTOS:
                // El nodo "Argumentos" no requiere comprobaciones especiales
                break;

            case Categoría.ARGUMENTO:
                auto a1 = cast(Argumento)(*n);
                auto a2 = cast(Argumento)(*m);
                // El nodo "Argumento" tiene las siguientes variables:
                // a.nombre, .tipo
                if(a1.nombre != a2.nombre)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "Argumento1.nombre y Argumento2.nombre no coinciden:\n["
                    ~ to!dstring(a1.nombre) ~ "] vs ["
                    ~ to!dstring(a2.nombre) ~ "]");

                    return false;
                }
                else if(!compara_árboles(cast(Nodo *)(&(a1.tipo)), cast(Nodo *)(&(a2.tipo))))
                {
                    writeln("PRUEBA!!");
                    bool ch = CHARLATÁN;
                    CHARLATÁN = true;
                    imprime_árbol(a1);
                    imprime_árbol(a2);
                    CHARLATÁN = ch;

                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "Argumento1.tipo y Argumento2.tipo no coinciden:\n["
                    ~ to!dstring(a1.tipo) ~ "] vs ["
                    ~ to!dstring(a2.tipo) ~ "]");

                    return false;
                }
                break;

            case Categoría.DEFINE_FUNCIÓN:
                auto df1 = cast(DefineFunción)(*n);
                auto df2 = cast(DefineFunción)(*m);
                // El nodo "DefineFunción" tiene las siguientes variables:
                // df.nombre, .retorno
                if(df1.nombre != df2.nombre)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "DefineFunción1.nombre y DefineFunción2.nombre no coinciden:\n["
                    ~ to!dstring(df1.nombre) ~ "] vs ["
                    ~ to!dstring(df2.nombre) ~ "]");

                    return false;
                }
                else if(!compara_árboles(cast(Nodo *)(&(df1.retorno)), cast(Nodo *)(&(df2.retorno))))
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "DefineFunción1.retorno y DefineFunción2.retorno no coinciden:\n["
                    ~ to!dstring(df1.retorno) ~ "] vs ["
                    ~ to!dstring(df2.retorno) ~ "]");

                    return false;
                }
                break;

            case Categoría.DECLARA_FUNCIÓN:
                auto df1 = cast(DeclaraFunción)(*n);
                auto df2 = cast(DeclaraFunción)(*m);
                // El nodo "DeclaraFunción" tiene las siguientes variables:
                // df.nombre, .retorno
                if(df1.nombre != df2.nombre)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "DeclaraFunción1.nombre y DeclaraFunción2.nombre no coinciden:\n["
                    ~ to!dstring(df1.nombre) ~ "] vs ["
                    ~ to!dstring(df2.nombre) ~ "]");

                    return false;
                }
                else if(!compara_árboles(cast(Nodo *)(&(df1.retorno)), cast(Nodo *)(&(df2.retorno))))
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "DeclaraFunción1.nombre y DeclaraFunción2.nombre no coinciden:\n["
                    ~ to!dstring(df1.retorno) ~ "] vs ["
                    ~ to!dstring(df2.retorno) ~ "]");

                    return false;
                }
                break;

            case Categoría.MÓDULO:
                auto obj1 = cast(Módulo)(*n);
                auto obj2 = cast(Módulo)(*m);
                // El nodo "Módulo" tiene las siguientes variables:
                // obj.nombre
                if(obj1.nombre != obj2.nombre)
                {
                    aborta(módulo, n.línea, "compara_nodos(Nodo1, Nodo2): \n"
                    ~ "Módulo1.nombre y Módulo2.nombre no coinciden:\n["
                    ~ to!dstring(obj1.nombre) ~ "] vs ["
                    ~ to!dstring(obj2.nombre) ~ "]");

                    return false;
                }
                break;

            default:
                aborta(módulo, n.línea, "Error al comparar los árboles de nodos: no existen reglas para este nodo");
                return false;
                //break;
        }

        return true;
    }

    avisa(módulo, 0, "Alguno de los nodos es nulo, no puedo realizar una comparación de árboles");

    return false;
}

bool compara_árboles(Nodo* a, Nodo* b)
{
    if(a is null)
    {
        return false;
    }
    else if(b is null)
    {
        return false;
    }
    else
    {
        if(!compara_nodos(a, b))
        {
            return false;
        }
        else if(a.ramas.length != b.ramas.length)
        {
            return false;
        }
        else
        {
            for(int i = 0; i < a.ramas.length; i++)
            {
                if(!compara_árboles(&(a.ramas[i]), &(b.ramas[i])))
                {
                    return false;
                }
            }

            return true;
        }
    }
}

bool tipo_natural(Nodo n)
{
    if(n.categoría == Categoría.TIPO)
    {
        Tipo t = cast(Tipo)n;
        uint32_t tamaño;

        if(t.tipo[0] == 'n')
        {
            tamaño = to!uint32_t(t.tipo[1..$]);

            if(tamaño >= 1 && tamaño <= 64)
            {
                return true;
            }
        }
    }
    
    return false;
}

bool tipo_entero(Nodo n)
{
    if(n.categoría == Categoría.TIPO)
    {
        Tipo t = cast(Tipo)n;
        uint32_t tamaño;

        if(t.tipo[0] == 'e')
        {
            tamaño = to!uint32_t(t.tipo[1..$]);

            if(tamaño >= 2 && tamaño <= 64)
            {
                return true;
            }
        }
    }
    
    return false;
}

bool tipo_real(Nodo n)
{
    if(n.categoría == Categoría.TIPO)
    {
        Tipo t = cast(Tipo)n;
        uint32_t tamaño;

        if(t.tipo[0] == 'r')
        {
            tamaño = to!uint32_t(t.tipo[1..$]);

            if(tamaño == 8 || tamaño == 16|| tamaño == 32|| tamaño == 64)
            {
                return true;
            }
        }
    }
    
    return false;
}