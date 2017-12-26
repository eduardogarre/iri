module semantico;

dstring módulo = "Semántico.d";

import apoyo;
import arbol;
static import lexico;
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

    paso_comprueba_concordancia_declaración_y_definición();

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
                    if(l.tipo is null)
                    {

                    }
                    else
                    {
                        charlatán("] [tipo:");
                        charlatán(l.tipo.tipo);
                    }
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
    foreach(ref EntradaTablaIdentificadores eid; tid_global.tabla)
    {
        // en cada iteración, eid contiene una entrada con un id global

        // Analiza sólo los id's que ya están definidos
        if(eid.definido)
        {
            Nodo def = eid.definición;

            switch(def.categoría)
            {
                case Categoría.DEFINE_IDENTIFICADOR_GLOBAL:
                    auto did = cast(DefineIdentificadorGlobal)def;
                    comprueba_tipo_literal(did.tipo, eid.valor);
                    break;

                case Categoría.DEFINE_FUNCIÓN:
                    auto dfn = cast(DefineFunción)def;
                    break;

                default: break;
            }
        }
    }
}

void paso_comprueba_concordancia_declaración_y_definición()
{
    // recorre los id's globales
    foreach(ref EntradaTablaIdentificadores eid; tid_global.tabla)
    {
        // en cada iteración, eid contiene una entrada con un id global

        // Analiza sólo los id's que ya están definidos
        if(eid.definido)
        {
            Nodo def = eid.definición;

            switch(def.categoría)
            {
                case Categoría.DEFINE_IDENTIFICADOR_GLOBAL:
                    auto defid = cast(DefineIdentificadorGlobal)def;
                    // Si existe declaración, comprueba que coincide con definición
                    if(eid.declarado)
                    {
                        Nodo dec = eid.declaración;
                        auto decid = cast(DeclaraIdentificadorGlobal)dec;

                        if(defid.dato != decid.dato)
                        {
                            aborta(módulo, defid.línea, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                            ~ "DefineIdentificadorGlobal.dato y DeclaraIdentificadorGlobal.dato no coinciden:\n["
                            ~ to!dstring(defid.dato) ~ "] vs ["
                            ~ to!dstring(decid.dato) ~ "]");
                        }
                        else if(defid.ámbito != decid.ámbito)
                        {
                            aborta(módulo, defid.línea, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                            ~ "DefineIdentificadorGlobal.ámbito y DeclaraIdentificadorGlobal.ámbito no coinciden:\n["
                            ~ to!dstring(defid.ámbito) ~ "] vs ["
                            ~ to!dstring(decid.ámbito) ~ "]");
                        }
                        else if(defid.nombre != decid.nombre)
                        {
                            aborta(módulo, defid.línea, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                            ~ "DefineIdentificadorGlobal.nombre y DeclaraIdentificadorGlobal.nombre no coinciden:\n["
                            ~ to!dstring(defid.nombre) ~ "] vs ["
                            ~ to!dstring(decid.nombre) ~ "]");
                        }
                        else if(!compara_árboles(cast(Nodo*)(&(defid.tipo)), cast(Nodo*)(&(decid.tipo))))
                        {
                            aborta(módulo, defid.línea, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                            ~ "DefineIdentificadorGlobal.tipo y DeclaraIdentificadorGlobal.tipo no coinciden:\n["
                            ~ to!dstring(defid.tipo) ~ "] vs ["
                            ~ to!dstring(decid.tipo) ~ "]");
                        }
                    }
                    break;

                case Categoría.DEFINE_FUNCIÓN:
                    auto deffn = cast(DefineFunción)def;
                    // Si existe declaración, comprueba que coincide con definición
                    if(eid.declarado)
                    {
                        Nodo dec = eid.declaración;
                        auto decfn = cast(DeclaraFunción)dec;

                        if(deffn.dato != decfn.dato)
                        {
                            aborta(módulo, deffn.línea, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                            ~ "DefineFunción.dato y DeclaraFunción.dato no coinciden:\n["
                            ~ to!dstring(deffn.dato) ~ "] vs ["
                            ~ to!dstring(decfn.dato) ~ "]");
                        }
                        else if(deffn.nombre != decfn.nombre)
                        {
                            aborta(módulo, deffn.línea, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                            ~ "DefineFunción.nombre y DeclaraFunción.nombre no coinciden:\n["
                            ~ to!dstring(deffn.nombre) ~ "] vs ["
                            ~ to!dstring(decfn.nombre) ~ "]");
                        }
                        else if(!compara_árboles(cast(Nodo*)(&(deffn.retorno)), cast(Nodo*)(&(decfn.retorno))))
                        {
                            aborta(módulo, deffn.línea, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                            ~ "DefineFunción.retorno y DeclaraFunción.retorno no coinciden:\n["
                            ~ to!dstring(deffn.retorno) ~ "] vs ["
                            ~ to!dstring(decfn.retorno) ~ "]");
                        }
                        else if(!compara_árboles(cast(Nodo*)(&(deffn.ramas[0])), cast(Nodo*)(&(decfn.ramas[0]))))
                        {
                            aborta(módulo, deffn.línea, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                            ~ "DefineFunción.ramas[0] y DeclaraFunción.ramas[0] (Argumentos) no coinciden:\n["
                            ~ to!dstring(deffn.ramas[0]) ~ "] vs ["
                            ~ to!dstring(decfn.ramas[0]) ~ "]");
                        }
                    }
                    break;

                default: break;
            }
        }
    }
}

void comprueba_tipo_literal(ref Tipo t, ref Literal l)
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
            uint64_t elementos = to!uint64_t(t.elementos);
            if(t.ramas.length < 1)
            {
                aborta(módulo, t.línea, "El vector no define un tipo que lo componga");
            }

            if(l.ramas.length != elementos)
            {
                aviso(módulo, t.línea, "El vector y el literal definen tamaños diferentes");
            }

            // Comprueba el tipo con los literales que componen el vector
            // Aparentemente, al hacer una conversión de tipos se pierde la referencia
            // Implemento la conversión mediante punteros.
            Tipo* tipo  = cast(Tipo*)(&(t.ramas[0]));
            for(int i = 0; i < l.ramas.length; i++)
            {
                Literal* li = cast(Literal*)(&(l.ramas[i]));
                comprueba_tipo_literal(*tipo, *li);
            }
            l.tipo = t;
        }
        else if(t.estructura)
        {
            if(t.ramas.length < 1)
            {
                aborta(módulo, t.línea, "La estructura no define un tipos que la compongan");
            }

            if(l.ramas.length != t.ramas.length)
            {
                aviso(módulo, t.línea, "La estructura y el literal definen tamaños diferentes");
            }

            // Comprueba el tipo con los literales que componen la estructura
            // Aparentemente, al hacer una conversión de tipos se pierde la referencia
            // Implemento la conversión mediante punteros.
            for(int i = 0; i < l.ramas.length; i++)
            {
                Tipo* tipo  = cast(Tipo*)(&(t.ramas[i]));
                Literal* li = cast(Literal*)(&(l.ramas[i]));

                comprueba_tipo_literal(*tipo, *li);
            }
            l.tipo = t;
        }
        else
        {
            // es un tipo simple

            uint32_t tamaño;

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
                    uint64_t tamaño_máximo;
                    uint64_t mitad_tamaño = pow(2, tamaño-2);
                    
                    tamaño_máximo = mitad_tamaño + (mitad_tamaño -1);

                    if(dato > tamaño_máximo)
                    {
                        aborta(módulo, t.línea, "El valor del literal '" ~ l.dato
                            ~ "' no cabe " ~ "en el tipo '" ~ t.tipo ~ "'");
                    }

                    ////////////////////////////////////////////////////////////
                    // Fin de las comprobaciones
                    // Si no hay errores, podemos asignar el tipo al literal
                    l.tipo = t;
                    break;

                case 'e':
                    ////////////////////////////////////////////////////////////
                    // Comprueba que el tamaño del tipo entero está dentro de
                    // lo especificado (2-64 dígitos)
                    if(tamaño < 2 || tamaño > 64)
                    {
                        aborta(módulo, t.línea, "Tamaño inválido para un entero: '"
                            ~ t.tipo[1..$] ~ "'. Debería estar en el rango 2-64");
                    }

                    ////////////////////////////////////////////////////////////
                    // Comprueba que el literal contiene un número entero
                    if(l.dato.length < 1)
                    {
                        aborta(módulo, t.línea, "El literal está vacío");
                    }

                    // el número es negativo
                    int desplazamiento = 0;
                    if(l.dato[0] == '-')
                    {
                        desplazamiento++;
                        if(l.dato.length < 1)
                        {
                            aborta(módulo, t.línea, "El literal '" ~ l.dato
                                ~ "' no es un número entero");
                        }
                    }

                    for(int i = desplazamiento; i < l.dato.length; i++)
                    {
                        if(!esdígito(l.dato[i]))
                        {
                            aborta(módulo, t.línea, "El literal '" ~ l.dato
                                ~ "' no es un número entero");
                        }
                    }

                    ////////////////////////////////////////////////////////////
                    // El valor del literal debe caber en el tipo
                    int64_t dato = to!int64_t(l.dato);
                    int64_t tamaño_máximo, tamaño_mínimo;
                    int64_t mitad_tamaño = pow(2, tamaño-2);
                    
                    tamaño_máximo = mitad_tamaño + (mitad_tamaño -1);
                    tamaño_mínimo = - mitad_tamaño - mitad_tamaño;

                    if((dato > tamaño_máximo) || (dato < tamaño_mínimo))
                    {
                        aborta(módulo, t.línea, "El valor del literal '" ~ l.dato
                            ~ "' no cabe " ~ "en el tipo '" ~ t.tipo ~ "'");
                    }

                    ////////////////////////////////////////////////////////////
                    // Fin de las comprobaciones
                    // Si no hay errores, podemos asignar el tipo al literal
                    l.tipo = t;
                    break;

                case 'r':
                    ////////////////////////////////////////////////////////////
                    // Comprueba que el tamaño del tipo real está dentro de
                    // lo especificado (8|16|32|64 dígitos)
                    if((tamaño != 8) && (tamaño != 16) && (tamaño != 32) && (tamaño != 64))
                    {
                        aborta(módulo, t.línea, "Tamaño inválido para un real: '"
                            ~ t.tipo[1..$] ~ "'. Debería ser uno de los siguientes: 8, 16, 32 ó 64");
                    }

                    ////////////////////////////////////////////////////////////
                    // Comprueba que el literal contiene un número entero
                    // Aprovecho las funciones en el módulo Léxico
                    lexico.cursor = 0;
                    lexico.código = l.dato ~ "\n";
                    
                    bool res = lexico.número();
                    
                    if(!res)
                    {
                        aborta(módulo, t.línea, "El literal '" ~ l.dato
                                ~ "' no es un número real");
                    }
                    else
                    {
                        if(lexico.cursor != l.dato.length)
                        {
                        aborta(módulo, t.línea, "El literal '" ~ l.dato
                                ~ "' no es un número real correcto");
                        }
                    }

                    ////////////////////////////////////////////////////////////
                    // El valor del literal debe caber en el tipo
                    // En el estándar de notación con coma flotante, si
                    // sobrepasa el tipo máximo se convierte a infinito
                    
                    ////////////////////////////////////////////////////////////
                    // Fin de las comprobaciones
                    // Si no hay errores, podemos asignar el tipo al literal
                    l.tipo = t;

                    break;

                default: break;
            }
        }
    }
}