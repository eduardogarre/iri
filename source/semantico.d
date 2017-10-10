module semantico;

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


// Para el análisis semántico creo una tabla desechable de identificadores.
TablaIdentificadores tid;

Nodo analiza(Nodo n)
{
    charlatánln("Análisis semántico.");
    imprime_árbol(n);

	charlatánln();

    paso1_obtén_identificadores_globales(n);

    charlatánln();

    return n;
}

private uint profundidad_árbol_gramatical = 0;

void imprime_árbol(Nodo n)
{
    profundidad_árbol_gramatical++;

    if(n)
    {
        for(int i = 1; i < profundidad_árbol_gramatical; i++)
        {
            charlatán("   ");
        }
        charlatán("[hijos:");
        charlatán(to!dstring(n.ramas.length));
        charlatán("] ");
        
        switch(n.categoría)
        {
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
                charlatán(" [tipo:");
                charlatán(l.tipo);
                charlatán("] [dato:");
                charlatán(l.dato);
                charlatán("] [línea:");
                charlatán(to!dstring(l.línea));
                charlatánln("]");
                break;

            case Categoría.IDENTIFICADOR:
                auto l = cast(Identificador)n;
                charlatán(to!dstring(l.categoría));
                charlatán(" [id:");
                charlatán(l.dato);
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

            case Categoría.DEFINE_IDENTIFICADOR_LOCAL:
                auto did = cast(DefineIdentificadorLocal)n;
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

void paso1_obtén_identificadores_globales(Nodo n)
{
    if(n)
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

                // Debería tener colgando un hijo de clase 'Literal'
                if(did.ramas.length != 1)
                {
                    aborta("El nodo DefineIdentificadorGlobal debería tener un hijo 'Literal'");
                }

                if(did.ramas[0].categoría != Categoría.LITERAL)
                {
                    aborta("El nodo DefineIdentificadorGlobal debería tener un hijo 'Literal'");
                }

                Literal lit = cast(Literal)(did.ramas[0]);

                if(tid.define_identificador(did.nombre, did, lit))
                {
                    charlatánln("define " ~ tid.lee_id(did.nombre).nombre);
                }

                break;

            case Categoría.DECLARA_IDENTIFICADOR_GLOBAL:
                auto idex = cast(DeclaraIdentificadorGlobal)n;

                if(tid.declara_identificador(idex.nombre, idex))
                {
                    charlatánln("declara " ~ tid.lee_id(idex.nombre).nombre);
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

                if(tid.define_identificador(df.nombre, df, null))
                {
                    charlatánln("define " ~ tid.lee_id(df.nombre).nombre);
                }

                break;

            case Categoría.DECLARA_FUNCIÓN:
                auto df = cast(DeclaraFunción)n;

                if(tid.declara_identificador(df.nombre, df))
                {
                    charlatánln("declara " ~ tid.lee_id(df.nombre).nombre);
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

        int i;
        for(i = 0; i < n.ramas.length; i++)
        {
            paso1_obtén_identificadores_globales(n.ramas[i]);
        }
    }
}