module compilador;

dstring módulo = "Compilador.d";

import apoyo;
import arbol;
import gcf;
import longevidad;
static import semantico;
import std.conv;
import std.stdio;

// Para la compilación creo una tabla desechable para los identificadores globales.
TablaIdentificadores tid_global;

Nodo compila(Nodo n)
{
    Nodo nodo = n;

    // Durante la compilación, guardo las nuevas estructuras en definiciones de
    // los identificadores, en la Tabla de Identificadores Globales.

    // Obtén los identificadores globales
    obtén_identificadores_globales(nodo);

    // Modifica cada función para incluir un Grafo de Control de Flujo
    compila_identificadores_globales(tid_global);

    //vuelca_tid(tid_global);

    return nodo;
}

// Rellena tid_global con los id's globales, tanto variables como funciones,
// independientemente de que sean declarados o definidos
void obtén_identificadores_globales(Nodo n)
{
    if(n)
    {
        switch(n.categoría)
        {
            case Categoría.DEFINE_IDENTIFICADOR_GLOBAL:
                auto did = cast(DefineIdentificadorGlobal)n;
                
                // Debería tener colgando un hijo de clase 'Literal'
                if(did.ramas.length != 1)
                {
                    aborta(módulo, n.posición, "El nodo DefineIdentificadorGlobal debería tener un hijo 'Literal'");
                }

                if(did.ramas[0].categoría != Categoría.LITERAL)
                {
                    aborta(módulo, n.posición, "El nodo DefineIdentificadorGlobal debería tener un hijo 'Literal'");
                }

                Literal lit = cast(Literal)(did.ramas[0]);

                if(tid_global.define_identificador(did.nombre, did, lit))
                {
                    charlatánln("define " ~ tid_global.lee_id(did.nombre).nombre);
                }

                break;

            case Categoría.DECLARA_IDENTIFICADOR_GLOBAL:
                auto idex = cast(DeclaraIdentificadorGlobal)n;

                if(tid_global.declara_identificador(idex.nombre, idex))
                {
                    charlatánln("declara " ~ tid_global.lee_id(idex.nombre).nombre);
                }

                break;

            case Categoría.DEFINE_FUNCIÓN:
                auto df = cast(DefineFunción)n;

                if(tid_global.define_identificador(df.nombre, df, null))
                {
                    charlatánln("define " ~ tid_global.lee_id(df.nombre).nombre);
                }

                break;

            case Categoría.DECLARA_FUNCIÓN:
                auto df = cast(DeclaraFunción)n;

                if(tid_global.declara_identificador(df.nombre, df))
                {
                    charlatánln("declara " ~ tid_global.lee_id(df.nombre).nombre);
                }

                break;

            case Categoría.MÓDULO:
                auto obj = cast(Módulo)n;

                // Crea la tabla de identificadores global, y la asocio al módulo.
                tid_global = new TablaIdentificadores(obj);

                tid_global.dueño = obj;

                break;

            default: break;
        }

        int i;
        for(i = 0; i < n.ramas.length; i++)
        {
            obtén_identificadores_globales(n.ramas[i]);
        }
    }
}

void compila_identificadores_globales(ref TablaIdentificadores tid)
{
    // recorre los id's globales
    foreach(ref EntradaTablaIdentificadores eid; tid.tabla)
    {
        // Cada iteración guardo un identificador global en eid

        // Analiza definiciones ...
        if(eid.definido)
        {
            Nodo def = eid.definición;

            // ... de funciones
            if(def.categoría == Categoría.DEFINE_FUNCIÓN)
            {
                compila_función(def, eid);
            }
        }
    }
}

void compila_función(ref Nodo func, ref EntradaTablaIdentificadores eid)
{
    // Verborrea...
    auto deffn = cast(DefineFunción)func;
    charlatánln();
    charlatánln("Compilando " ~ deffn.nombre ~ "()");

    // El grafo de la función se guarda en el árbol de su definición, accesible
    // a través de la Tabla de Identificadores
    genera_grafo_control_flujo(func, eid);

    // Obtengo longevidad
    Longevidad[][] longevidad = obtén_longevidad(func, false);
}