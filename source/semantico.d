module semantico;

import apoyo;
import arbol;
import std.stdio;

// Implemento la tabla de identificadores como un diccionario:
// Para acceder a cada una de las entradas, se usa el nombre del identificador.

TablaIdentificadores tid;

bool analiza(Nodo n)
{
    imprime_árbol(n);

	writeln();

    paso1_identificadores_globales(n);

    return true;
}

void paso1_identificadores_globales(Nodo n)
{
    paso1_recorre_nodo(n);
}

struct EntradaTablaIdentificadores
{
    dstring nombre;
    bool declarado;
    Nodo declaración;
    bool definido;
    Nodo definición;
}

class TablaIdentificadores
{
    TablaIdentificadores padre;
    TablaIdentificadores hijo;

    this(TablaIdentificadores padre, Nodo dueño)
    {
        this.padre = padre;
        this.dueño = dueño;

        if(padre !is null)
        {
            this.padre.pon_hijo(this);
        }
    }

    void pon_hijo(TablaIdentificadores hijo)
    {
        this.hijo = hijo;
    }

    TablaIdentificadores lee_hijo()
    {
        return this.hijo;
    }

    void borra_hijo()
    {
        this.hijo = null;
    }


    Nodo dueño;

    EntradaTablaIdentificadores[dstring] tabla;

    EntradaTablaIdentificadores lee_id(dstring identificador)
    {

        dstring id = identificador;

        if((identificador[0] == '@') || (identificador[0] == '%'))
        {
            id = identificador[1..$];
        }

        return tabla[id];
    }

    bool declara_identificador(dstring identificador, Nodo declaración)
    {
        if(identificador is null)
        {
            error("Me has pasado un identificador nulo");
            return false;
        }

        dstring id = identificador;

        if((identificador[0] == '@') || (identificador[0] == '%'))
        {
            id = identificador[1..$];
        }

        if(id in tabla)
        {
            // El identificador ya está en uso.
            error("Ya estabas usando el identificador '" ~ id ~ "'");
            return false;
        }

        EntradaTablaIdentificadores eid;

        eid.nombre = id;
        eid.declarado = true;
        eid.declaración = declaración;

        tabla[id] = eid;

        return true;
    }

    bool define_identificador(dstring identificador, Nodo definición)
    {
        if(identificador is null)
        {
            error("Me has pasado un identificador nulo");
            return false;
        }

        dstring id = identificador;

        if((identificador[0] == '@') || (identificador[0] == '%'))
        {
            id = identificador[1..$];
        }

        EntradaTablaIdentificadores eid;

        if(id in tabla)
        {
            // El identificador ya está en uso.
            if(tabla[id].definido)
            {
                error("Ya habías definido el identificador '" ~ id ~ "'");

                return false;
            }

            eid = tabla[id];
        }

        eid.nombre = id;
        eid.definido = true;
        eid.definición = definición;

        tabla[id] = eid;

        return true;
    }
}

private uint profundidad_árbol_gramatical = 0;

void imprime_árbol(Nodo n)
{
    recorre_nodo(n);
}

void recorre_nodo(Nodo n)
{
    profundidad_árbol_gramatical++;

    if(n)
    {
        for(int i = 1; i < profundidad_árbol_gramatical; i++)
        {
            write("   ");
        }
        write("[hijos:");
        write(n.ramas.length);
        write("] ");
        interpreta_nodo(n);

        int i;
        for(i = 0; i < n.ramas.length; i++)
        {
            recorre_nodo(n.ramas[i]);
        }
    }

    profundidad_árbol_gramatical--;
}

private void interpreta_nodo(Nodo n)
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

        case Categoría.DEFINE_IDENTIFICADOR_LOCAL:
            auto did = cast(DefineIdentificadorLocal)n;
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

        case Categoría.DEFINE_IDENTIFICADOR_GLOBAL:
            auto did = cast(DefineIdentificadorGlobal)n;
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

        case Categoría.DECLARA_IDENTIFICADOR_GLOBAL:
            auto idex = cast(DeclaraIdentificadorGlobal)n;
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

        case Categoría.MÓDULO:
            auto obj = cast(Módulo)n;
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

void paso1_recorre_nodo(Nodo n)
{
    if(n)
    {
        paso1_interpreta_nodo(n);

        int i;
        for(i = 0; i < n.ramas.length; i++)
        {
            paso1_recorre_nodo(n.ramas[i]);
        }
    }
}

private void paso1_interpreta_nodo(Nodo n)
{
    switch(n.categoría)
    {
        case Categoría.LITERAL:
            auto l = cast(Literal)n;
            break;

        case Categoría.IDENTIFICADOR:
            auto l = cast(Identificador)n;
            break;

        case Categoría.OPERACIÓN:
            auto o = cast(Operación)n;
            break;

        case Categoría.ASIGNACIÓN:
            auto a = cast(Asignación)n;
            break;

        case Categoría.DEFINE_IDENTIFICADOR_LOCAL:
            auto did = cast(DefineIdentificadorLocal)n;
            break;

        case Categoría.DEFINE_IDENTIFICADOR_GLOBAL:
            auto did = cast(DefineIdentificadorGlobal)n;

            if(tid.define_identificador(did.nombre, did))
            {
                writeln("define " ~ tid.lee_id(did.nombre).nombre);
            }

            break;

        case Categoría.DECLARA_IDENTIFICADOR_GLOBAL:
            auto idex = cast(DeclaraIdentificadorGlobal)n;

            if(tid.declara_identificador(idex.nombre, idex))
            {
                writeln("declara " ~ tid.lee_id(idex.nombre).nombre);
            }

            break;

        case Categoría.BLOQUE:
            auto b = cast(Bloque)n;
            break;

        case Categoría.ARGUMENTOS:
            auto a = cast(Argumentos)n;
            break;

        case Categoría.ARGUMENTO:
            auto a = cast(Argumento)n;
            break;

        case Categoría.DEFINE_FUNCIÓN:
            auto df = cast(DefineFunción)n;

            if(tid.define_identificador(df.nombre, df))
            {
                writeln("define " ~ tid.lee_id(df.nombre).nombre);
            }

            break;

        case Categoría.DECLARA_FUNCIÓN:
            auto df = cast(DeclaraFunción)n;

            if(tid.declara_identificador(df.nombre, df))
            {
                writeln("declara " ~ tid.lee_id(df.nombre).nombre);
            }

            break;

        case Categoría.MÓDULO:
            auto obj = cast(Módulo)n;

            // Crea la tabla de identificadores global, y la asocio al módulo.
            auto globtid = new TablaIdentificadores(null, obj);

            obj.tid(&globtid);
            tid = globtid;

            break;

        default: break;
    }
}