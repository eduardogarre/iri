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

    writeln();

    paso2_ejecuta_inicio();

    return true;
}

void paso1_identificadores_globales(Nodo n)
{
    writeln("Recorre espacio de nombres 'global'.");

    paso1_recorre_nodo(n);
}

void paso2_ejecuta_inicio()
{
    writeln("Ejecuta '@inicio()'.");
    
    if(tid.lee_id("inicio").nombre != "inicio")
    {
        aborta("No has declarado la función '@inicio()'");
    }

    EntradaTablaIdentificadores eid = tid.lee_id("inicio");
    // eid: dstring nombre, bool declarado, Nodo declaración, bool definido, Nodo definición;

    if(!eid.definido)
    {
        aborta("No has definido la función '@inicio()'");
    }

    // Obtén en Nodo de la definición de @inicio()
    DefineFunción def_inicio = cast(DefineFunción)eid.definición;

    // Crea y configura la tabla de identificadores de la función @inicio()
    auto tid_inicio = new TablaIdentificadores(tid, def_inicio);
    tid_inicio.dueño = def_inicio;

    // Establece la tabla de ids de @inicio() como la tid vigente.
    tid = tid_inicio;

    // Declara los argumentos de @inicio().
    paso2_1_declara_argumentos(def_inicio);

    // Define los argumentos de @inicio(): r32 pi 3.14159
    auto literal = new Literal();
    literal.dato = "3.14159";
    literal.tipo = "r32";
    literal.línea = def_inicio.línea;
    tid.define_identificador("pi", literal);

    // Comprueba las variables guardadas en las tablas de identificadores
    writeln("Comprobando que %pi existe...");
    recorre_nodo(tid.lee_id("%pi").definición);

    writeln("Comprobando que %lolazo existe...");
    recorre_nodo(tid.lee_id("%lolazo").definición);


    //paso 2.2: obtén el bloque de @inicio(), para poder ejecutarlo.
    Bloque bloque = paso2_2_obtén_bloque(def_inicio);

    if(bloque is null)
    {
        aborta("No puedo ejecutar el bloque de @inicio");
    }

    //paso 2.3: recorre las ramas del bloque de @inicio()
    for(int i = 0; i<bloque.ramas.length; i++)
    {
        auto n = bloque.ramas[i];

        switch(n.categoría)
        {
            case Categoría.OPERACIÓN:
                Operación o = cast(Operación)n;
                if(!ejecuta_operación(o))
                {
                    aborta("Ocurrió un problema ejecutando la operación");
                }

                break;

            default:
                break;
        }
    }
}

void paso2_1_declara_argumentos(Nodo n)
{
    writeln("Declara los argumentos de @inicio().");
    
    paso2_1_recorre_nodo(n);
}

Bloque paso2_2_obtén_bloque(Nodo nodo)
{
    Bloque bloque = null;

    for(int i = 0; i<nodo.ramas.length; i++)
    {
        Nodo r = cast(Nodo)nodo.ramas[i];
        if(r.categoría == Categoría.BLOQUE)
        {
            bloque = cast(Bloque)r;
            break;
        }
    }

    return bloque;
}

struct EntradaTablaIdentificadores
{
    dstring nombre;
    bool    declarado;
    Nodo    declaración;
    bool    definido;
    Nodo    definición;
    Literal valor;
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

        auto tmp = id in tabla;
        if(tmp is null)
        {
            //el identificador no se encuentra en la tabla actual
            if(this.padre is null)
            {
                // esta es la tabla raíz
                return EntradaTablaIdentificadores(null, false, null, false, null);
            }
            else
            {
                // examinar la tabla-padre
                return padre.lee_id(identificador);
            }
        }
        else
        {
            return tabla[id];
        }
    }

    bool declara_identificador(dstring identificador, Nodo declaración)
    {
        if(identificador is null)
        {
            aborta("Me has pasado un identificador nulo");
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
            aborta("Ya estabas usando el identificador '" ~ id ~ "'");
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
            aborta("Me has pasado un identificador nulo");
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
                aborta("Ya habías definido el identificador '" ~ id ~ "'");

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

            globtid.dueño = obj;

            tid = globtid;

            break;

        default: break;
    }
}

void paso2_1_recorre_nodo(Nodo n)
{
    if(n)
    {
        paso2_1_interpreta_nodo(n);

        int i;
        for(i = 0; i < n.ramas.length; i++)
        {
            paso2_1_recorre_nodo(n.ramas[i]);
        }
    }
}

private void paso2_1_interpreta_nodo(Nodo n)
{
    switch(n.categoría)
    {
        case Categoría.ARGUMENTO:
            auto a = cast(Argumento)n;

            if(tid.declara_identificador(a.nombre, a))
            {
                writeln("declara " ~ tid.lee_id(a.nombre).nombre);
            }
            break;

        default: break;
    }
}

Literal lee_argumento(Nodo n)
{
    Literal lit = null;

    if(n.categoría == Categoría.LITERAL)
    {
        lit = cast(Literal)n;
    }
    else if(n.categoría == Categoría.IDENTIFICADOR)
    {
        auto id = cast(Identificador)n;
        // Accediendo a %pi...
        Nodo l = (tid.lee_id("pi").definición);
        if(l.categoría == Categoría.LITERAL)
        {
            lit = cast(Literal)l;
        }
    }

    return lit;
}

bool ejecuta_operación(Operación op)
{
    switch(op.dato)
    {
        case "ret":
            if(op.ramas.length == 0)
            {
                // ret no tiene argumento
                writeln("op: ret");

                return true;
            }
            else if(op.ramas.length == 1)
            {
                // ret tiene argumento
                Nodo n = op.ramas[0];

                Literal lit = lee_argumento(n);
                if(lit is null)
                {
                    aborta("No he podido conseguir el argumento de op: ret []");
                }
                //auto lit = cast(Literal)(op.ramas[0]);
                writeln("op: ret " ~ lit.tipo ~ ":" ~ lit.dato);

                return true;
            }

            break;

        default:
            break;
    }

    return false;
}