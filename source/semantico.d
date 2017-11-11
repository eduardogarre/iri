module semantico;

dstring módulo = "Semántico.d";

import apoyo;
import arbol;
import std.conv;
import std.stdint;
import std.stdio;

// tareas a realizar durante el análisis semántico:
// Coincidencia de tipos
// Los argumentos con los que llamas a una función coinciden con la declaración
// de la función
// Todas las variables en la tabla están definidas
// Las variables son declaradas y definidas una sola vez en el ámbito activo


// Para el análisis semántico creo tablas desechables para los identificadores.
TablaIdentificadores tid_global;
TablaIdentificadores tid_local;

Nodo analiza(Nodo n)
{
    charlatánln("Análisis semántico.");
    imprime_árbol(n); // árbol antes del análisis semántico

	charlatánln();

    paso_obtén_identificadores_globales(n);

    charlatánln();

    imprime_árbol(n); // árbol después del análisis semántico

	charlatánln();

    return n;
}

private uint profundidad_árbol_gramatical = 0;

void imprime_árbol(Nodo n)
{
    profundidad_árbol_gramatical++;

    if(n)
    {
        if(n.etiqueta.length > 0)
        {
            charlatánln(n.etiqueta);
        }

        for(int i = 1; i < profundidad_árbol_gramatical; i++)
        {
            charlatán("   ");
        }
        charlatán("[hijos:");
        charlatán(to!dstring(n.ramas.length));
        charlatán("] ");
        
        switch(n.categoría)
        {
            case Categoría.ETIQUETA:
                auto e = cast(Etiqueta)n;
                charlatán(to!dstring(e.categoría));
                charlatán(" [");
                charlatán(e.dato);
                charlatán("] [línea:");
                charlatán(to!dstring(e.línea));
                charlatánln("]");
                break;

            case Categoría.TIPO:
                auto t = cast(Tipo)n;
                charlatán(to!dstring(t.categoría));
                if(t.vector)
                {
                    charlatán(" [" ~ to!dstring(t.elementos) ~ " x " ~ t.tipo);
                    charlatán("]");
                }
                else if(t.estructura)
                {
                    charlatán(" {estructura}");
                }
                else
                {
                    charlatán(" [tipo:" ~ t.tipo);
                    charlatán("]");
                }
                charlatán(" [línea:");
                charlatán(to!dstring(t.línea));
                charlatánln("]");
                break;

            case Categoría.RESERVADA:
                auto l = cast(Reservada)n;
                charlatán(to!dstring(l.categoría));
                charlatán("] [dato:");
                charlatán(l.dato);
                charlatán("] [línea:");
                charlatán(to!dstring(l.línea));
                charlatánln("]");
                break;

            case Categoría.LITERAL:
                auto l = cast(Literal)n;
                charlatán(to!dstring(l.categoría));
                if(l.vector)
                {
                    charlatán(" [vector]");
                }
                else if(l.estructura)
                {
                    charlatán(" {estructura}");
                }
                else
                {
                    charlatán(" [tipo:");
                    charlatán(l.tipo);
                    charlatán("] [dato:");
                    charlatán(l.dato ~ "]");
                }
                charlatán(" [línea:");
                charlatán(to!dstring(l.línea));
                charlatánln("]");
                break;

            case Categoría.IDENTIFICADOR:
                auto l = cast(Identificador)n;
                charlatán(to!dstring(l.categoría));
                charlatán(" [id:");
                charlatán(l.nombre);
                charlatán("] [línea:");
                charlatán(to!dstring(l.línea));
                charlatánln("]");
                break;

            case Categoría.LLAMA_FUNCIÓN:
                auto l = cast(LlamaFunción)n;
                charlatán(to!dstring(l.categoría));
                charlatán(" [id:");
                charlatán(l.nombre);
                charlatán(" [devuelve:");
                charlatán(l.tipo);
                charlatán("] [línea:");
                charlatán(to!dstring(l.línea));
                charlatánln("]");
                break;

            case Categoría.OPERACIÓN:
                auto o = cast(Operación)n;
                charlatán(to!dstring(o.categoría));
                charlatán(" [op:");
                charlatán(o.dato);
                charlatán("] [línea:");
                charlatán(to!dstring(o.línea));
                charlatánln("]");
                break;

            case Categoría.ASIGNACIÓN:
                auto a = cast(Asignación)n;
                charlatán(to!dstring(a.categoría));
                charlatán(" [línea:");
                charlatán(to!dstring(a.línea));
                charlatánln("]");
                break;

            case Categoría.DEFINE_IDENTIFICADOR_GLOBAL:
                auto did = cast(DefineIdentificadorGlobal)n;
                charlatán(to!dstring(did.categoría));
                charlatán(" [ámbito:");
                charlatán(did.ámbito);
                charlatán("] [tipo:");
                charlatán(did.tipo);
                charlatán("] [nombre:");
                charlatán(did.nombre);
                charlatán("] [línea:");
                charlatán(to!dstring(did.línea));
                charlatánln("]");
                break;

            case Categoría.DECLARA_IDENTIFICADOR_GLOBAL:
                auto idex = cast(DeclaraIdentificadorGlobal)n;
                charlatán(to!dstring(idex.categoría));
                charlatán(" [ámbito:");
                charlatán(idex.ámbito);
                charlatán("] [tipo:");
                charlatán(idex.tipo);
                charlatán("] [nombre:");
                charlatán(idex.nombre);
                charlatán("] [línea:");
                charlatán(to!dstring(idex.línea));
                charlatánln("]");
                break;

            case Categoría.BLOQUE:
                auto b = cast(Bloque)n;
                charlatán(to!dstring(b.categoría));
                charlatán(" [línea:");
                charlatán(to!dstring(b.línea));
                charlatánln("]");
                break;

            case Categoría.ARGUMENTOS:
                auto a = cast(Argumentos)n;
                charlatán(to!dstring(a.categoría));
                charlatán(" [línea:");
                charlatán(to!dstring(a.línea));
                charlatánln("]");
                break;

            case Categoría.ARGUMENTO:
                auto a = cast(Argumento)n;
                charlatán(to!dstring(a.categoría));
                charlatán(" [tipo:");
                charlatán(a.tipo);
                charlatán("] [nombre:");
                charlatán(a.nombre);
                charlatán("] [línea:");
                charlatán(to!dstring(a.línea));
                charlatánln("]");
                break;

            case Categoría.DEFINE_FUNCIÓN:
                auto df = cast(DefineFunción)n;
                charlatán(to!dstring(df.categoría));
                charlatán(" [ret:");
                charlatán(df.retorno);
                charlatán("] [nombre:");
                charlatán(df.nombre);
                charlatán("] [línea:");
                charlatán(to!dstring(df.línea));
                charlatánln("]");
                break;

            case Categoría.DECLARA_FUNCIÓN:
                auto df = cast(DeclaraFunción)n;
                charlatán(to!dstring(df.categoría));
                charlatán(" [ret:");
                charlatán(df.retorno);
                charlatán("] [nombre:");
                charlatán(df.nombre);
                charlatán("] [línea:");
                charlatán(to!dstring(df.línea));
                charlatánln("]");
                break;

            case Categoría.MÓDULO:
                auto obj = cast(Módulo)n;
                charlatán(to!dstring(obj.categoría));
                charlatán(" [nombre:");
                charlatán(obj.nombre);
                charlatán("] [línea:");
                charlatán(to!dstring(obj.línea));
                charlatánln("]");
                break;

            default: break;
        }

        int i;
        for(i = 0; i < n.ramas.length; i++)
        {
            imprime_árbol(n.ramas[i]);
        }
    }

    profundidad_árbol_gramatical--;
}

// Rellena tid_global con los id's globales, tanto variables como funciones,
// independientemente de que sean declarados o definidos
void paso_obtén_identificadores_globales(Nodo n)
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
                    aborta(módulo, n.línea, "El nodo DefineIdentificadorGlobal debería tener un Nodo hijo de categoría 'Literal'");
                }

                if(did.ramas[0].categoría != Categoría.LITERAL)
                {
                    aborta(módulo, n.línea, "El nodo DefineIdentificadorGlobal debería tener un Nodo hijo de categoría 'Literal'");
                }

                Literal lit = cast(Literal)(did.ramas[0]);

                
                EntradaTablaIdentificadores id = tid_global.lee_id(did.nombre);
                
                if(id.declarado)
                {
                    // Comprueba que la declaración y la definición coinciden
                }

                if(id.definido)
                {
                    aborta(módulo, did.línea, "Ya habías definido la variable global " ~ did.nombre);
                }

                if(tid_global.define_identificador(did.nombre, did, lit))
                {
                    charlatánln("define " ~ tid_global.lee_id(did.nombre).nombre);
                }

                break;

            case Categoría.DECLARA_IDENTIFICADOR_GLOBAL:
                auto idex = cast(DeclaraIdentificadorGlobal)n;

                EntradaTablaIdentificadores id = tid_global.lee_id(idex.nombre);
                
                if(id.declarado)
                {
                    aborta(módulo, idex.línea, "Ya habías declarado la variable global " ~ idex.nombre);
                }

                if(id.definido)
                {
                    // Comprueba que la declaración y la definición coinciden
                }

                if(tid_global.declara_identificador(idex.nombre, idex))
                {
                    charlatánln("declara " ~ tid_global.lee_id(idex.nombre).nombre);
                }

                break;

            case Categoría.DEFINE_FUNCIÓN:
                auto df = cast(DefineFunción)n;

                EntradaTablaIdentificadores id = tid_global.lee_id(df.nombre);
                
                if(id.declarado)
                {
                    // Comprueba que la declaración y la definición coinciden
                }

                if(id.definido)
                {
                    aborta(módulo, df.línea, "Ya habías definido " ~ df.nombre ~ "()");
                }

                if(tid_global.define_identificador(df.nombre, df, null))
                {
                    charlatánln("define " ~ tid_global.lee_id(df.nombre).nombre);
                }

                break;

            case Categoría.DECLARA_FUNCIÓN:
                auto df = cast(DeclaraFunción)n;

                EntradaTablaIdentificadores id = tid_global.lee_id(df.nombre);
                
                if(id.declarado)
                {
                    aborta(módulo, df.línea, "Ya habías declarado " ~ df.nombre ~ "()");
                }

                if(id.definido)
                {
                    // Comprueba que la declaración y la definición coinciden
                }

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
            paso_obtén_identificadores_globales(n.ramas[i]);
        }
    }
}