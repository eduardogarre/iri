module semantico;

dstring módulo = "Semántico.d";

import apoyo;
import arbol;
import std.conv;
import std.math;
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

    paso_comprueba_tipos_ids_globales();

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
                if(did.tipo !is null)
                {
                    charlatán("] [tipo:");
                    charlatán((cast(Tipo)(did.tipo)).tipo);
                }
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
                charlatán((cast(Tipo)(idex.tipo)).tipo);
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
                charlatán(a.tipo.tipo);
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
                charlatán(df.retorno.tipo);
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
                charlatán((cast(Tipo)(df.retorno)).tipo);
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

void paso_comprueba_tipos_ids_globales()
{
    // recorre los id's globales
    foreach(EntradaTablaIdentificadores eid; tid_global.tabla)
    {
        // en cada iteración, eid contiene una entrada con un id global

        // Analiza sólo los id's que ya están definidos
        if(eid.definido)
        {
            Nodo n = eid.definición;

            switch(n.categoría)
            {
                case Categoría.DEFINE_IDENTIFICADOR_GLOBAL:
                    auto did = cast(DefineIdentificadorGlobal)n;
                    comprueba_tipo_literal(did.tipo, eid.valor);
                    break;

                case Categoría.DEFINE_FUNCIÓN:
                    auto df = cast(DefineFunción)n;
                    break;

                default: break;
            }
        }
    }
}

void comprueba_tipo_literal(Tipo t, Literal l)
{
    if(t is null)
    {
        if(l is null)
        {
            aborta(módulo, 0, "El tipo y el literal son nulos");
        }
        else
        {
            aborta(módulo, l.línea, "El tipo es nulo");
        }
    }
    else if(l is null)
    {
        aborta(módulo, t.línea, "El literal es nulo");
    }
    else
    {
        // El tipo y el literal son válidos
        if(t.vector)
        {

        }
        else if(t.estructura)
        {

        }
        else
        {
            // es un tipo simple

            uint32_t tamaño;
            uint64_t tamaño_máximo;

            dchar dc = t.tipo[0];

            if((dc == 'n') || (dc == 'e') || (dc == 'r'))
            {
                tamaño = to!uint32_t(t.tipo[1..$]);
            }
            else
            {
                aborta(módulo, t.línea, "Tipo no válido: '" ~ t.tipo ~ "'");
            }

            switch(t.tipo[0])
            {
                case 'n':
                    ////////////////////////////////////////////////////////////
                    // Comprueba que el tamaño del tipo natural está dentro de
                    // lo especificado (1-64 dígitos)
                    if(tamaño < 1 || tamaño > 64)
                    {
                        aborta(módulo, t.línea, "Tamaño inválido para un natural: '"
                            ~ t.tipo[1..$] ~ "'. Debería estar en el rango 1-64");
                    }

                    ////////////////////////////////////////////////////////////
                    // Comprueba que el literal contiene un número natural
                    if(l.dato.length < 1)
                    {
                        aborta(módulo, t.línea, "El literal está vacío");
                    }

                    for(int i = 0; i < l.dato.length; i++)
                    {
                        if(!esdígito(l.dato[i]))
                        {
                            aborta(módulo, t.línea, "El literal '" ~ l.dato
                                ~ "' no es un número natural");
                        }
                    }

                    ////////////////////////////////////////////////////////////
                    // El valor del literal debe caber en el tipo
                    uint64_t dato = to!uint64_t(l.dato);
                    tamaño_máximo = pow(2, tamaño-1) + (pow(2, tamaño-1) -1);

                    if(dato > tamaño_máximo)
                    {
                        aborta(módulo, t.línea, "El valor del literal '" ~ l.dato
                            ~ "' no cabe " ~ "en el tipo '" ~ t.tipo ~ "'");
                    }

                    ////////////////////////////////////////////////////////////
                    // Fin de las comprobaciones
                    break;

                case 'e':
                    if(tamaño < 2 || tamaño > 64)
                    {
                        aborta(módulo, t.línea, "Tamaño inválido para un entero: '"
                            ~ t.tipo[1..$] ~ "'. Debería estar en el rango 2-64");
                    }

                    break;

                case 'r':
                    if(tamaño != 8 || tamaño != 16 || tamaño != 32 || tamaño != 64)
                    {
                        aborta(módulo, t.línea, "Tamaño inválido para un real: '"
                            ~ t.tipo[1..$] ~ "'. Debería ser uno de los siguientes: 8, 16, 32 ó 64");
                    }

                    break;

                default: break;
            }
        }
    }
}