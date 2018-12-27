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

    paso_comprueba_concordancia_declaraciones_y_definiciones();

    paso_comprueba_funciones();

    // Examina tid_global, para detectar identificadores no usados
    tid_global.encuentra_ids_no_usados();

    // Vuelco el contenido de la tabla de identificadores global
    //vuelca_tid(tid_global);

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
                charlatán(to!dstring(e.posición.línea));
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
                charlatán(to!dstring(t.posición.línea));
                charlatánln("]");
                break;

            case Categoría.RESERVADA:
                auto l = cast(Reservada)n;
                charlatán(to!dstring(l.categoría));
                charlatán("] [dato:");
                charlatán(l.dato);
                charlatán("] [línea:");
                charlatán(to!dstring(l.posición.línea));
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
                charlatán(to!dstring(l.posición.línea));
                charlatánln("]");
                break;

            case Categoría.IDENTIFICADOR:
                auto l = cast(Identificador)n;
                charlatán(to!dstring(l.categoría));
                charlatán(" [id:");
                charlatán(l.nombre);
                charlatán("] [línea:");
                charlatán(to!dstring(l.posición.línea));
                charlatánln("]");
                break;

            case Categoría.LLAMA_FUNCIÓN:
                auto l = cast(LlamaFunción)n;
                charlatán(to!dstring(l.categoría));
                charlatán(" [id:");
                charlatán(l.nombre);
                charlatán(" [devuelve:");
                charlatán(to!dstring(l.retorno));
                charlatán("] [línea:");
                charlatán(to!dstring(l.posición.línea));
                charlatánln("]");
                break;

            case Categoría.OPERACIÓN:
                auto o = cast(Operación)n;
                charlatán(to!dstring(o.categoría));
                charlatán(" [op:");
                charlatán(o.dato);
                charlatán("] [línea:");
                charlatán(to!dstring(o.posición.línea));
                charlatánln("]");
                break;

            case Categoría.ASIGNACIÓN:
                auto a = cast(Asignación)n;
                charlatán(to!dstring(a.categoría));
                charlatán(" [línea:");
                charlatán(to!dstring(a.posición.línea));
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
                charlatán(to!dstring(did.posición.línea));
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
                charlatán(to!dstring(idex.posición.línea));
                charlatánln("]");
                break;

            case Categoría.BLOQUE:
                auto b = cast(Bloque)n;
                charlatán(to!dstring(b.categoría));
                charlatán(" [línea:");
                charlatán(to!dstring(b.posición.línea));
                charlatánln("]");
                break;

            case Categoría.ARGUMENTOS:
                auto a = cast(Argumentos)n;
                charlatán(to!dstring(a.categoría));
                charlatán(" [línea:");
                charlatán(to!dstring(a.posición.línea));
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
                charlatán(to!dstring(a.posición.línea));
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
                charlatán(to!dstring(df.posición.línea));
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
                charlatán(to!dstring(df.posición.línea));
                charlatánln("]");
                break;

            case Categoría.MÓDULO:
                auto obj = cast(Módulo)n;
                charlatán(to!dstring(obj.categoría));
                charlatán(" [nombre:");
                charlatán(obj.nombre);
                charlatán("] [línea:");
                charlatán(to!dstring(obj.posición.línea));
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
                    aborta(módulo, n.posición, "El nodo DefineIdentificadorGlobal debería tener un Nodo hijo de categoría 'Literal'");
                }

                if(did.ramas[0].categoría != Categoría.LITERAL)
                {
                    aborta(módulo, n.posición, "El nodo DefineIdentificadorGlobal debería tener un Nodo hijo de categoría 'Literal'");
                }

                Literal lit = cast(Literal)(did.ramas[0]);

                
                EntradaTablaIdentificadores id = tid_global.lee_id(did.nombre);
                
                if(id.declarado)
                {
                    // Comprueba que la declaración y la definición coinciden
                }

                if(id.definido)
                {
                    aborta(módulo, did.posición, "Ya habías definido la variable global " ~ did.nombre);
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
                    aborta(módulo, idex.posición, "Ya habías declarado la variable global " ~ idex.nombre);
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
                    aborta(módulo, df.posición, "Ya habías definido " ~ df.nombre ~ "()");
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
                    aborta(módulo, df.posición, "Ya habías declarado " ~ df.nombre ~ "()");
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

void paso_comprueba_concordancia_declaraciones_y_definiciones()
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
                
                comprueba_tipo_literal(defid.tipo, eid.valor);
                
                if(eid.declarado) // Si existe declaración, comprueba que coincide con definición
                {
                    auto decid = cast(DeclaraIdentificadorGlobal)(eid.declaración);

                    if(defid.dato != decid.dato)
                    {
                        aborta(módulo, defid.posición, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                        ~ "DefineIdentificadorGlobal.dato y DeclaraIdentificadorGlobal.dato no coinciden:\n["
                        ~ to!dstring(defid.dato) ~ "] vs ["
                        ~ to!dstring(decid.dato) ~ "]");
                    }
                    else if(defid.ámbito != decid.ámbito)
                    {
                        aborta(módulo, defid.posición, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                        ~ "DefineIdentificadorGlobal.ámbito y DeclaraIdentificadorGlobal.ámbito no coinciden:\n["
                        ~ to!dstring(defid.ámbito) ~ "] vs ["
                        ~ to!dstring(decid.ámbito) ~ "]");
                    }
                    else if(defid.nombre != decid.nombre)
                    {
                        aborta(módulo, defid.posición, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                        ~ "DefineIdentificadorGlobal.nombre y DeclaraIdentificadorGlobal.nombre no coinciden:\n["
                        ~ to!dstring(defid.nombre) ~ "] vs ["
                        ~ to!dstring(decid.nombre) ~ "]");
                    }
                    else if(!compara_árboles(cast(Nodo*)(&(defid.tipo)), cast(Nodo*)(&(decid.tipo))))
                    {
                        aborta(módulo, defid.posición, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                        ~ "DefineIdentificadorGlobal.tipo y DeclaraIdentificadorGlobal.tipo no coinciden:\n["
                        ~ to!dstring(defid.tipo) ~ "] vs ["
                        ~ to!dstring(decid.tipo) ~ "]");
                    }
                }
                break;

            case Categoría.DEFINE_FUNCIÓN:
                auto deffn = cast(DefineFunción)def;
                
                if(eid.declarado) // Si existe declaración, comprueba que coincide con definición
                {
                    auto decfn = cast(DeclaraFunción)(eid.declaración);

                    if(deffn.dato != decfn.dato)
                    {
                        aborta(módulo, deffn.posición, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                        ~ "DefineFunción.dato y DeclaraFunción.dato no coinciden:\n["
                        ~ to!dstring(deffn.dato) ~ "] vs ["
                        ~ to!dstring(decfn.dato) ~ "]");
                    }
                    else if(deffn.nombre != decfn.nombre)
                    {
                        aborta(módulo, deffn.posición, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                        ~ "DefineFunción.nombre y DeclaraFunción.nombre no coinciden:\n["
                        ~ to!dstring(deffn.nombre) ~ "] vs ["
                        ~ to!dstring(decfn.nombre) ~ "]");
                    }
                    else if(!compara_árboles(cast(Nodo*)(&(deffn.retorno)), cast(Nodo*)(&(decfn.retorno))))
                    {
                        aborta(módulo, deffn.posición, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
                        ~ "DefineFunción.retorno y DeclaraFunción.retorno no coinciden:\n["
                        ~ to!dstring(deffn.retorno) ~ "] vs ["
                        ~ to!dstring(decfn.retorno) ~ "]");
                    }
                    else if(!compara_árboles(cast(Nodo*)(&(deffn.ramas[0])), cast(Nodo*)(&(decfn.ramas[0]))))
                    {
                        aborta(módulo, deffn.posición, "paso_comprueba_concordancia_declaración_y_definición()::compara_nodos(Nodo1, Nodo2): \n"
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
            aborta(módulo, null, "El tipo y el literal son nulos");
        }
        else
        {
            aborta(módulo, l.posición, "El tipo es nulo");
        }
    }
    else if(l is null)
    {
        aborta(módulo, t.posición, "El literal es nulo");
    }
    else // El tipo y el literal contienen un valor
    {
        if(t.vector) // El tipo es un vector
        {
            uint64_t elementos = to!uint64_t(t.elementos);
            if(t.ramas.length != 1) // El nodo Vector debe tener un nodo hijo Tipo, con el tipo que compone el vector
            {
                aborta(módulo, t.posición, "El vector no define un tipo que lo componga");
            }

            if(l.ramas.length != elementos) // El nodo Literal debe tener tantos hijos como elementos dice el Vector
            {
                avisa(módulo, t.posición, "El vector y el literal definen tamaños diferentes");
            }

            // Comprueba el tipo con los literales que componen el vector
            // Implemento la conversión mediante punteros.
            Tipo* tipo  = cast(Tipo*)(&(t.ramas[0])); // Extrae el tipo del vector
            for(int i = 0; i < l.ramas.length; i++)
            {
                Literal* li = cast(Literal*)(&(l.ramas[i])); // Extrae cada literal del vector
                comprueba_tipo_literal(*tipo, *li); // compara cada nodo Literal hijo con el noto Tipo hijo
            }

            // Aparentemente, al hacer una conversión de tipos se pierde la referencia
            l.tipo = t; // Asigno al literal el tipo correspondiente
        }
        else if(t.estructura) // El tipo es una estructura
        {
            if(t.ramas.length < 1) // El nodo Estructura debe tener al menos un nodo Tipo hijo
            {
                aborta(módulo, t.posición, "La estructura no define tipos que la compongan");
            }

            if(l.ramas.length != t.ramas.length) // El nodo Estructura debe tener tantos hijos (literales) como el nodo Tipo (tipos hijos)
            {
                avisa(módulo, t.posición, "La estructura y el literal definen tamaños diferentes");
            }

            // Comprueba el tipo con los literales que componen la estructura
            // Implemento la conversión mediante punteros.
            for(int i = 0; i < l.ramas.length; i++)
            {
                Tipo* tipo  = cast(Tipo*)(&(t.ramas[i])); // Extrae cada nodo Tipo hijo del nodo Tipo padre
                Literal* li = cast(Literal*)(&(l.ramas[i])); // Extrae cada Literal hijo del nodo Estructura padre

                comprueba_tipo_literal(*tipo, *li); // compara cada nodo Literal hijo con el noto Tipo hijo
            }

            // Aparentemente, al hacer una conversión de tipos se pierde la referencia
            l.tipo = t; // Asigno al literal el tipo correspondiente
        }
        else // es un tipo simple
        {
            uint32_t tamaño;

            dchar dc = t.tipo[0];

            if((dc == 'n') || (dc == 'e') || (dc == 'r'))
            {
                tamaño = to!uint32_t(t.tipo[1..$]);
            }
            else
            {
                aborta(módulo, t.posición, "Tipo no válido: '" ~ t.tipo ~ "'");
            }

            switch(t.tipo[0])
            {
                case 'n':
                    ////////////////////////////////////////////////////////////
                    // Comprueba que el tamaño del tipo natural está dentro de
                    // lo especificado (1-64 dígitos)
                    if(tamaño < 1 || tamaño > 64)
                    {
                        aborta(módulo, t.posición, "Tamaño inválido para un natural: '"
                            ~ t.tipo[1..$] ~ "'. Debería estar en el rango 1-64");
                    }

                    ////////////////////////////////////////////////////////////
                    // Comprueba que el literal contiene un número natural
                    if(l.dato.length < 1)
                    {
                        aborta(módulo, t.posición, "El literal está vacío");
                    }

                    for(int i = 0; i < l.dato.length; i++)
                    {
                        if(!esdígito(l.dato[i]))
                        {
                            aborta(módulo, t.posición, "El literal '" ~ l.dato
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
                        aborta(módulo, t.posición, "El valor del literal '" ~ l.dato
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
                        aborta(módulo, t.posición, "Tamaño inválido para un entero: '"
                            ~ t.tipo[1..$] ~ "'. Debería estar en el rango 2-64");
                    }

                    ////////////////////////////////////////////////////////////
                    // Comprueba que el literal contiene un número entero
                    if(l.dato.length < 1)
                    {
                        aborta(módulo, t.posición, "El literal está vacío");
                    }

                    // el número es negativo
                    int desplazamiento = 0;
                    if(l.dato[0] == '-')
                    {
                        desplazamiento++;
                        if(l.dato.length < 1)
                        {
                            aborta(módulo, t.posición, "El literal '" ~ l.dato
                                ~ "' no es un número entero");
                        }
                    }

                    for(int i = desplazamiento; i < l.dato.length; i++)
                    {
                        if(!esdígito(l.dato[i]))
                        {
                            aborta(módulo, t.posición, "El literal '" ~ l.dato
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
                        aborta(módulo, t.posición, "El valor del literal '" ~ l.dato
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
                        aborta(módulo, t.posición, "Tamaño inválido para un real: '"
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
                        aborta(módulo, t.posición, "El literal '" ~ l.dato
                                ~ "' no es un número real");
                    }
                    else
                    {
                        if(lexico.cursor != l.dato.length)
                        {
                        aborta(módulo, t.posición, "El literal '" ~ l.dato
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

void paso_comprueba_funciones()
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
            case Categoría.DEFINE_FUNCIÓN:
                auto def_func = cast(DefineFunción)def;

                Bloque bloque = prepara_función(def_func);
                Nodo retorno = comprueba_bloque(bloque); // analiza semánticamente cada afirmación del bloque

                // Examina tid_local, para detectar identificadores no usados
                tid_local.encuentra_ids_no_usados();

                // Vuelco el contenido de la tabla de identificadores local
                //vuelca_tid(tid_local);

                // Fin de ejecución de la función:
                // Hay que eliminar la tabla de identificadores actual
                //tid_local = null;
                break;

            default:
                break;
            }
        }
    }

    // Compruebo que existe inicio;
    EntradaTablaIdentificadores inicio = tid_global.coge_id("@inicio");
    if(inicio == EntradaTablaIdentificadores(null, false, null, false, null, null))
    {
        // No existe una función @inicio()
        avisa(módulo, null, "No has definido una función '@inicio()'");
    }
}

Bloque prepara_función(DefineFunción def_func)
{
    posición3d posición_actual;

    if(def_func is null)
    {
        aborta(módulo, posición_actual, "Me has pasado un 'null' en lugar de una función.");
    }
    else
    {
        posición_actual = def_func.posición;
    }
    
    // Crea y configura la tabla de identificadores de la función
    auto tid_func = new TablaIdentificadores(def_func);
    tid_func.dueño = def_func;
    
    // Establece la tabla de ids de la función como la tid vigente.
    tid_local = tid_func;

    // Declara los argumentos de la función.
    charlatánln("Declara los argumentos de '" ~ def_func.nombre ~ "()'.");
    declara_argumentos(def_func);

    // Obtén el bloque de la función, para poder ejecutarlo.
    Bloque bloque = obtén_bloque(def_func);

    if(bloque is null)
    {
        aborta(módulo, posición_actual, "No puedo ejecutar el bloque");
    }

    obtén_etiquetas(bloque);

    return bloque;
}

void declara_argumentos(Nodo n)
{
    if(n)
    {
        switch(n.categoría)
        {
            case Categoría.ARGUMENTO:
                auto a = cast(Argumento)n;

                if(tid_local.declara_identificador(a.nombre, a.tipo))
                {
                    charlatánln("declara " ~ tid_local.lee_id(a.nombre).nombre);
                }
                break;

            case Categoría.ARGUMENTOS:
                for(int i = 0; i < n.ramas.length; i++)
                {
                    declara_argumentos(n.ramas[i]);
                }
                break;

            case Categoría.DEFINE_FUNCIÓN:
                declara_argumentos(n.ramas[0]);
                break;

            default: break;
        }
    }
}

Bloque obtén_bloque(Nodo nodo)
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

void obtén_etiquetas(Nodo n)
{
    if(n)
    {
        tid_local.define_identificador(":", null, null);

        for(int i = 0; i < n.ramas.length; i++)
        {
            if(n.ramas[i].etiqueta.length > 0)
            {
                auto lit = new Literal();
                lit.dato = to!dstring(i-1);
                lit.tipo = new Tipo();
                lit.tipo.tipo = "nada";
                lit.posición = n.ramas[i].posición;

                if(tid_local.define_identificador(n.ramas[i].etiqueta, null, lit))
                {
                    charlatánln("ETIQUETA: " ~ tid_local.lee_id(n.ramas[i].etiqueta).nombre);
                }
            }
        }
    }
}

Nodo comprueba_bloque(Bloque bloque)
{
    Nodo resultado;
    //recorre las ramas del bloque
    for(int i = 0; i<bloque.ramas.length; i++)
    {
        comprueba_nodo(bloque.ramas[i]);
    }

    return resultado;
}

Nodo comprueba_nodo(Nodo n)
{
    if(n)
    {
        switch(n.categoría)
        {
            case Categoría.OPERACIÓN:
                auto o = cast(Operación)n;
                
                return comprueba_operación(o);
                //break;

            case Categoría.ASIGNACIÓN:
                auto a = cast(Asignación)n;

                auto id = cast(Identificador)a.ramas[0];

                auto tipo = cast(Tipo)comprueba_nodo(a.ramas[1]);

                if(tipo is null || tipo.categoría != Categoría.TIPO)
                {
                    aborta(módulo, a.posición, "El operador del lado derecho no declara ningún tipo.");
                }

                tid_local.declara_identificador(id.nombre, tipo);

                return null;
                //break;

            default:
                aborta(módulo, n.posición, "No reconozco el Nodo.");

                return null;
                //break;
        }
    }

    return null;
}

Nodo coge_identificador(Nodo n)
{
    if(n is null)
    {
        aborta(módulo, null, "Has pasado como argumento un Nodo nulo");
    }

    if(n.categoría == Categoría.IDENTIFICADOR)
    {
        auto id = cast(Identificador)n;

        EntradaTablaIdentificadores eid = tid_local.coge_id(id.nombre);
        if(eid == EntradaTablaIdentificadores(null, false, null, false, null, null))
        {
            eid = tid_global.coge_id(id.nombre);
        }

        if(eid.declarado) // Durante el análisis sintáctico, en la tabla de id's se guarda todo como declaración.
        {
            Nodo dec = eid.declaración;
            if(dec.categoría == Categoría.TIPO) // La declaración debe ser un Tipo
            {
                Tipo tlit = cast(Tipo)dec;
                
                return tlit;
            }
            else if(dec.categoría == Categoría.DECLARA_FUNCIÓN)
            {
                return dec;
            }
        }
        else if(eid.definido)
        {
            Nodo def = eid.definición;
            if(def.categoría == Categoría.DEFINE_IDENTIFICADOR_GLOBAL)
            {
                DefineIdentificadorGlobal def_id = cast(DefineIdentificadorGlobal)def;
                Tipo tid = def_id.tipo;

                return tid;
            }
        }

        aborta(módulo, n.posición, "En las tablas de identificadores no encuentro '" ~ id.nombre ~ "'.");
    }
    else
    {
        aborta(módulo, n.posición, "No has pasado un identificador.");
    }

    return null;
}

Nodo lee_identificador(Nodo n)
{
    if(n is null)
    {
        aborta(módulo, null, "Has pasado como argumento un Nodo nulo");
    }

    if(n.categoría == Categoría.IDENTIFICADOR)
    {
        auto id = cast(Identificador)n;

        EntradaTablaIdentificadores eid = tid_local.lee_id(id.nombre);
        if(eid == EntradaTablaIdentificadores(null, false, null, false, null, null))
        {
            eid = tid_global.lee_id(id.nombre);
        }

        if(eid.declarado) // Durante el análisis sintáctico, en la tabla de id's se guarda todo como declaración.
        {
            Nodo dec = eid.declaración;
            if(dec.categoría == Categoría.TIPO) // La declaración debe ser un Tipo
            {
                Tipo tlit = cast(Tipo)dec;
                
                return tlit;
            }
            else if(dec.categoría == Categoría.DECLARA_FUNCIÓN)
            {
                return dec;
            }
        }
        else if(eid.definido)
        {
            Nodo def = eid.definición;
            if(def.categoría == Categoría.DEFINE_IDENTIFICADOR_GLOBAL)
            {
                DefineIdentificadorGlobal def_id = cast(DefineIdentificadorGlobal)def;
                Tipo tid = def_id.tipo;

                return tid;
            }
        }

        aborta(módulo, n.posición, "En las tablas de identificadores no encuentro '" ~ id.nombre ~ "'.");
    }
    else
    {
        aborta(módulo, n.posición, "No has pasado un identificador.");
    }

    return null;
}

Tipo comprueba_operación(Operación op)
{
    switch(op.dato)
    {
        case "ret":
            return op_ret(op);
            //break;

        case "sum":
            return op_sum(op);
            //break;

        case "res":
            return op_res(op);
            //break;

        case "mul":
            return op_mul(op);
            //break;

        case "div":
            return op_div(op);
            //break;

        case "llama":
            return op_llama(op);
            //break;

        case "cmp":
            return op_cmp(op);
            //break;

        case "conv":
            return op_conv(op);
            //break;

        case "slt":
            return op_slt(op);
            //break;

        case "phi":
            return op_phi(op);
            //break;

        case "rsrva":
            return op_rsrva(op);
            //break;

        case "lee":
            return op_lee(op);
            //break;

        case "guarda":
            return op_guarda(op);
            //break;

        case "leeval":
            return op_leeval(op);
            //break;

        case "ponval":
            return op_ponval(op);
            //break;

        default:
            break;
    }

    return null;
}

Tipo op_ret(Operación op)
{
    if(op.dato != "ret")
    {
        aborta(módulo, op.posición, "Esperaba que el código de la operación fuera 'ret'");
        return null;
    }

    if(op.ramas.length == 2)
    {
        // ret <tipo> (<literal>|<id>);
        Tipo t = cast(Tipo)(op.ramas[0]);
        Nodo n = op.ramas[1];

        if(n.categoría == Categoría.LITERAL)
        {
            auto lit = cast(Literal)n;

            comprueba_tipo_literal(t, lit); // Si los tipos no coinciden, abortará.

            // Si el curso de ejecución llega hasta aquí, los tipos coincidían
            return t;
        }
        else if(n.categoría == Categoría.IDENTIFICADOR)
        {
            Tipo tlit;
            Nodo id = coge_identificador(n);
            if(id.categoría == Categoría.TIPO)
            {
                tlit = cast(Tipo)id;
            }
            else
            {
                aborta(módulo, n.posición, "No he podido obtener un tipo para el identificador '" ~ n.dato ~ "'");
            }
            
            Nodo nt1 = cast(Nodo)t;
            Nodo nt2 = cast(Nodo)tlit;

            if(compara_árboles(&nt1, &nt2))
            {
                return t;
            }
            else
            {
                aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
            }
        }
    }
    else if(op.ramas.length == 0)
    {
        // ret;
        infoln("op: ret");
        return null;
    }
    else
    {
        aborta(módulo, op.posición, "Esperaba que 'ret' tuviera uno o ningún argumento");
        return null;
    }

    return null;
}

Tipo op_sum(Operación op)
{
    if(op.dato != "sum")
    {
        aborta(módulo, op.posición, "Esperaba que el código de la operación fuera 'sum'");
        return null;
    }

    if(op.ramas.length != 3)
    {
        aborta(módulo, op.posición, "sum <tipo> <arg1>, <arg2>");
        return null;
    }

    Nodo n;
    Tipo t = cast(Tipo)(op.ramas[0]);
    
    // Comprobaciones entre el tipo y el primer argumento de la operación
    n = op.ramas[1];
    if(n.categoría == Categoría.LITERAL)
    {
        Literal l = cast(Literal)n;
        comprueba_tipo_literal(t, l);
    }
    else if(n.categoría == Categoría.IDENTIFICADOR)
    {
        Tipo tlit;
        Nodo id = coge_identificador(n);
        if(id.categoría == Categoría.TIPO)
        {
            tlit = cast(Tipo)id;
        }
        else
        {
            aborta(módulo, n.posición, "No he podido obtener un tipo para el identificador '" ~ n.dato ~ "'");
        }

        Nodo nt1 = cast(Nodo)t;
        Nodo nt2 = cast(Nodo)tlit;

        if(!compara_árboles(&nt1, &nt2))
        {
            aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
        }
    }
    
    // Comprobaciones entre el tipo y el segundo argumento de la operación
    n = op.ramas[2];
    if(n.categoría == Categoría.LITERAL)
    {
        Literal l = cast(Literal)n;
        comprueba_tipo_literal(t, l);
    }
    else if(n.categoría == Categoría.IDENTIFICADOR)
    {
        Tipo tlit;
        Nodo id = coge_identificador(n);
        if(id.categoría == Categoría.TIPO)
        {
            tlit = cast(Tipo)id;
        }
        else
        {
            aborta(módulo, n.posición, "No he podido obtener un tipo para el identificador '" ~ n.dato ~ "'");
        }

        Nodo nt1 = cast(Nodo)t;
        Nodo nt2 = cast(Nodo)tlit;

        if(!compara_árboles(&nt1, &nt2))
        {
            aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
        }
    }

    // Si llegamos hasta aquí, todas las comprobaciones han sido correctas
    return t;
}

Tipo op_res(Operación op)
{
    if(op.dato != "res")
    {
        aborta(módulo, op.posición, "Esperaba que el código de la operación fuera 'res'");
        return null;
    }

    if(op.ramas.length != 3)
    {
        aborta(módulo, op.posición, "res <tipo> <arg1>, <arg2>");
        return null;
    }

    Nodo n;
    Tipo t = cast(Tipo)(op.ramas[0]);
    
    // Comprobaciones entre el tipo y el primer argumento de la operación
    n = op.ramas[1];
    if(n.categoría == Categoría.LITERAL)
    {
        Literal l = cast(Literal)n;
        comprueba_tipo_literal(t, l);
    }
    else if(n.categoría == Categoría.IDENTIFICADOR)
    {
        Tipo tlit;
        Nodo id = coge_identificador(n);
        if(id.categoría == Categoría.TIPO)
        {
            tlit = cast(Tipo)id;
        }
        else
        {
            aborta(módulo, n.posición, "No he podido obtener un tipo para el identificador '" ~ n.dato ~ "'");
        }

        Nodo nt1 = cast(Nodo)t;
        Nodo nt2 = cast(Nodo)tlit;

        if(!compara_árboles(&nt1, &nt2))
        {
            aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
        }
    }
    
    // Comprobaciones entre el tipo y el segundo argumento de la operación
    n = op.ramas[2];
    if(n.categoría == Categoría.LITERAL)
    {
        Literal l = cast(Literal)n;
        comprueba_tipo_literal(t, l);
    }
    else if(n.categoría == Categoría.IDENTIFICADOR)
    {
        Tipo tlit;
        Nodo id = coge_identificador(n);
        if(id.categoría == Categoría.TIPO)
        {
            tlit = cast(Tipo)id;
        }
        else
        {
            aborta(módulo, n.posición, "No he podido obtener un tipo para el identificador '" ~ n.dato ~ "'");
        }

        Nodo nt1 = cast(Nodo)t;
        Nodo nt2 = cast(Nodo)tlit;

        if(!compara_árboles(&nt1, &nt2))
        {
            aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
        }
    }

    // Si llegamos hasta aquí, todas las comprobaciones han sido correctas
    return t;
}

Tipo op_mul(Operación op)
{
    if(op.dato != "mul")
    {
        aborta(módulo, op.posición, "Esperaba que el código de la operación fuera 'mul'");
        return null;
    }

    if(op.ramas.length != 3)
    {
        aborta(módulo, op.posición, "mul <tipo> <arg1>, <arg2>");
        return null;
    }

    Nodo n;
    Tipo t = cast(Tipo)(op.ramas[0]);
    
    // Comprobaciones entre el tipo y el primer argumento de la operación
    n = op.ramas[1];
    if(n.categoría == Categoría.LITERAL)
    {
        Literal l = cast(Literal)n;
        comprueba_tipo_literal(t, l);
    }
    else if(n.categoría == Categoría.IDENTIFICADOR)
    {
        Tipo tlit;
        Nodo id = coge_identificador(n);
        if(id.categoría == Categoría.TIPO)
        {
            tlit = cast(Tipo)id;
        }
        else
        {
            aborta(módulo, n.posición, "No he podido obtener un tipo para el identificador '" ~ n.dato ~ "'");
        }

        Nodo nt1 = cast(Nodo)t;
        Nodo nt2 = cast(Nodo)tlit;

        if(!compara_árboles(&nt1, &nt2))
        {
            aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
        }
    }
    
    // Comprobaciones entre el tipo y el segundo argumento de la operación
    n = op.ramas[2];
    if(n.categoría == Categoría.LITERAL)
    {
        Literal l = cast(Literal)n;
        comprueba_tipo_literal(t, l);
    }
    else if(n.categoría == Categoría.IDENTIFICADOR)
    {
        Tipo tlit;
        Nodo id = coge_identificador(n);
        if(id.categoría == Categoría.TIPO)
        {
            tlit = cast(Tipo)id;
        }
        else
        {
            aborta(módulo, n.posición, "No he podido obtener un tipo para el identificador '" ~ n.dato ~ "'");
        }

        Nodo nt1 = cast(Nodo)t;
        Nodo nt2 = cast(Nodo)tlit;

        if(!compara_árboles(&nt1, &nt2))
        {
            aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
        }
    }

    // Si llegamos hasta aquí, todas las comprobaciones han sido correctas
    return t;
}

Tipo op_div(Operación op)
{
    if(op.dato != "div")
    {
        aborta(módulo, op.posición, "Esperaba que el código de la operación fuera 'div'");
        return null;
    }

    if(op.ramas.length != 3)
    {
        aborta(módulo, op.posición, "div <tipo> <arg1>, <arg2>");
        return null;
    }

    Nodo n;
    Tipo t = cast(Tipo)(op.ramas[0]);
    
    // Comprobaciones entre el tipo y el primer argumento de la operación
    n = op.ramas[1];
    if(n.categoría == Categoría.LITERAL)
    {
        Literal l = cast(Literal)n;
        comprueba_tipo_literal(t, l);
    }
    else if(n.categoría == Categoría.IDENTIFICADOR)
    {
        Tipo tlit;
        Nodo id = coge_identificador(n);
        if(id.categoría == Categoría.TIPO)
        {
            tlit = cast(Tipo)id;
        }
        else
        {
            aborta(módulo, n.posición, "No he podido obtener un tipo para el identificador '" ~ n.dato ~ "'");
        }

        Nodo nt1 = cast(Nodo)t;
        Nodo nt2 = cast(Nodo)tlit;

        if(!compara_árboles(&nt1, &nt2))
        {
            aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
        }
    }
    
    // Comprobaciones entre el tipo y el segundo argumento de la operación
    n = op.ramas[2];
    if(n.categoría == Categoría.LITERAL)
    {
        Literal l = cast(Literal)n;
        comprueba_tipo_literal(t, l);
    }
    else if(n.categoría == Categoría.IDENTIFICADOR)
    {
        Tipo tlit;
        Nodo id = coge_identificador(n);
        if(id.categoría == Categoría.TIPO)
        {
            tlit = cast(Tipo)id;
        }
        else
        {
            aborta(módulo, n.posición, "No he podido obtener un tipo para el identificador '" ~ n.dato ~ "'");
        }

        Nodo nt1 = cast(Nodo)t;
        Nodo nt2 = cast(Nodo)tlit;

        if(!compara_árboles(&nt1, &nt2))
        {
            aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
        }
    }

    // Si llegamos hasta aquí, todas las comprobaciones han sido correctas
    return t;
}

Tipo op_llama(Operación op)
{
    if(op.dato != "llama")
    {
        aborta(módulo, op.posición, "Esperaba que el código de la operación fuera 'llama'");
        return null;
    }

    if(op.ramas.length != 1)
    {
        aborta(módulo, op.posición, "Esperaba que la operación 'llama' se acompañara de una función");
        return null;
    }

    LlamaFunción f = cast(LlamaFunción)op.ramas[0];

    // Obtengo la función de la tabla de id's global
    if(tid_global.lee_id(f.nombre).nombre is null)
    {
        aborta(módulo, op.posición, "La función '" ~ f.nombre ~ "()' es desconocida.");
    }
    
    // eid: dstring nombre, bool declarado, Nodo declaración, bool definido, Nodo definición;
    EntradaTablaIdentificadores eid = tid_global.coge_id(f.nombre);

    Nodo nt1;
    Nodo nt2;

    Argumentos args;

    if(eid.declarado)
    {
        // Obtén el Nodo de la definición
        DeclaraFunción dec_func = cast(DeclaraFunción)eid.declaración;

        // Comparo tipos de retorno
        nt1 = cast(Nodo)(f.retorno);
        nt2 = cast(Nodo)(dec_func.retorno);
        
        if(!compara_árboles(&nt1, &nt2))
        {
            aborta(módulo, op.posición, "El tipo de retorno no coincide con el declarado.");
        }

        // Comparo tipos de los argumentos
        for(int i = 0; i < f.ramas.length; i++)
        {
            Argumento a = cast(Argumento)(dec_func.ramas[0].ramas[i]);
            Tipo t = a.tipo;

            Nodo arg = f.ramas[i];
            if(arg.categoría == Categoría.LITERAL)
            {
                Literal l = cast(Literal)arg;
                comprueba_tipo_literal(t, l);
            }
            else if(arg.categoría == Categoría.IDENTIFICADOR)
            {
                Nodo id = coge_identificador(arg);
                if(id.categoría != Categoría.TIPO)
                {
                    aborta(módulo, arg.posición, "No he podido obtener un tipo para el identificador '" ~ arg.dato ~ "'");
                }

                nt1 = cast(Nodo)t;
                nt2 = cast(Nodo)id;

                if(!compara_árboles(&nt1, &nt2))
                {
                    aborta(módulo, op.posición, "La firma de la función no coincide con la declarada previamente.");
                }
            }
        }

        return f.retorno;
    }
    else if(eid.definido)
    {
        // Obtén el Nodo de la definición
        DefineFunción def_func = cast(DefineFunción)eid.definición;

        // Comparo tipos de retorno
        nt1 = cast(Nodo)(f.retorno);
        nt2 = cast(Nodo)(def_func.retorno);
        
        if(!compara_árboles(&nt1, &nt2))
        {
            aborta(módulo, op.posición, "El tipo de retorno no coincide con el declarado.");
        }

        for(int i = 0; i < f.ramas.length; i++)
        {
            Argumento a = cast(Argumento)(def_func.ramas[0].ramas[i]);
            Tipo t = a.tipo;

            Nodo arg = f.ramas[i];
            if(arg.categoría == Categoría.LITERAL)
            {
                Literal l = cast(Literal)arg;
                comprueba_tipo_literal(t, l);
            }
            else if(arg.categoría == Categoría.IDENTIFICADOR)
            {
                Nodo id = coge_identificador(arg);
                if(id.categoría != Categoría.TIPO)
                {
                    aborta(módulo, arg.posición, "No he podido obtener un tipo para el identificador '" ~ arg.dato ~ "'");
                }

                nt1 = cast(Nodo)t;
                nt2 = cast(Nodo)id;

                if(!compara_árboles(&nt1, &nt2))
                {
                    aborta(módulo, op.posición, "La firma de la función no coincide con la declrada previamente.");
                }
            }
        }

        return f.retorno;
    }
    
    aborta(módulo, op.posición, "La función '" ~ f.nombre ~ "()' es desconocida.");

    return null;
}

Tipo op_cmp(Operación op)
{
    if(op.dato != "cmp")
    {
        aborta(módulo, op.posición, "Esperaba que el código de la operación fuera 'cmp'");
        return null;
    }

    if(op.ramas.length != 4)
    {
        aborta(módulo, op.posición, "cmp <comparación> <tipo> (<literal>|<id>), (<literal>|<id>)");
        return null;
    }

    auto r = op.ramas[0];

    dstring comparación = r.dato;

    if(   (comparación == "ig") // igual
        | (comparación == "dsig") // diferente
        | (comparación == "ma") // mayor
        | (comparación == "me") // menor
        | (comparación == "maig") // mayor o igual
        | (comparación == "meig") // menor o igual
        )
    {}
    else
    {
        aborta(módulo, op.posición, "op:cmp - El comando de comparación es incorrecto");
    }

    Nodo n;
    Tipo t = cast(Tipo)(op.ramas[1]);
    
    // Comprobaciones entre el tipo y el primer argumento de la operación
    n = op.ramas[2];
    if(n.categoría == Categoría.LITERAL)
    {
        Literal l = cast(Literal)n;
        comprueba_tipo_literal(t, l);
    }
    else if(n.categoría == Categoría.IDENTIFICADOR)
    {
        Tipo tlit;
        Nodo id = coge_identificador(n);
        if(id.categoría == Categoría.TIPO)
        {
            tlit = cast(Tipo)id;
        }
        else
        {
            aborta(módulo, n.posición, "No he podido obtener un tipo para el identificador '" ~ n.dato ~ "'");
        }

        Nodo nt1 = cast(Nodo)t;
        Nodo nt2 = cast(Nodo)tlit;

        if(!compara_árboles(&nt1, &nt2))
        {
            aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
        }
    }
    
    // Comprobaciones entre el tipo y el segundo argumento de la operación
    n = op.ramas[3];
    if(n.categoría == Categoría.LITERAL)
    {
        Literal l = cast(Literal)n;
        comprueba_tipo_literal(t, l);
    }
    else if(n.categoría == Categoría.IDENTIFICADOR)
    {
        Tipo tlit;
        Nodo id = coge_identificador(n);
        if(id.categoría == Categoría.TIPO)
        {
            tlit = cast(Tipo)id;
        }
        else
        {
            aborta(módulo, n.posición, "No he podido obtener un tipo para el identificador '" ~ n.dato ~ "'");
        }

        Nodo nt1 = cast(Nodo)t;
        Nodo nt2 = cast(Nodo)tlit;

        if(!compara_árboles(&nt1, &nt2))
        {
            aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
        }
    }

    // Si llegamos hasta aquí, todas las comprobaciones han sido correctas
    // El resultado de una comparación siempre debe ser n1

    Tipo tipo_n1 = new Tipo();
    tipo_n1.tipo = "n1";
    tipo_n1.posición = op.posición;
    return tipo_n1;
}

Tipo op_conv(Operación op)
{
    if(op.dato != "conv")
    {
        aborta(módulo, op.posición, "Esperaba que el código de la operación fuera 'conv'");
        return null;
    }

    if(op.ramas.length != 3)
    {
        aborta(módulo, op.posición, "conv <tipo-origen> (<literal>|<id>) a <tipo-destino>)");
        return null;
    }

    Tipo origen = cast(Tipo)(op.ramas[0]);
    Tipo destino = (cast(Tipo)(op.ramas[2]));
    Nodo n = op.ramas[1];

    // Primero compruebo que el valor coincide con el Tipo origen
    if(n.categoría == Categoría.LITERAL)
    {
        Literal l = cast(Literal)n;
        comprueba_tipo_literal(origen, l);
    }
    else if(n.categoría == Categoría.IDENTIFICADOR)
    {
        Tipo tlit;
        Nodo id = coge_identificador(n);
        if(id.categoría == Categoría.TIPO)
        {
            tlit = cast(Tipo)id;
        }
        else
        {
            aborta(módulo, n.posición, "No he podido obtener un tipo para el identificador '" ~ n.dato ~ "'");
        }

        Nodo nt1 = cast(Nodo)origen;
        Nodo nt2 = cast(Nodo)tlit;

        if(!compara_árboles(&nt1, &nt2))
        {
            aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
        }
    }

    // Luego compruebo que la conversión es posible
    uint32_t tamaño_origen, tamaño_destino;

    switch(origen.tipo[0])
    {
        case 'n': // convertimos desde 'natural'
            tamaño_origen = to!uint32_t(origen.tipo[1..$]);
            if(tamaño_origen > 64)
            {
                aborta(módulo, op.posición, "op:conv - el tamaño del tipo máximo es 64 bits, y has"
                            ~ " pedido " ~ to!dstring(tamaño_origen) ~ "bits");
            }
            if(tamaño_origen < 1)
            {
                aborta(módulo, op.posición, "op:conv - el tamaño del tipo mínimo es 1 bit, y has"
                            ~ " pedido " ~ to!dstring(tamaño_origen) ~ "bits");
            }

            switch(destino.tipo[0])
            {
                case 'n': // convertimos de natural a natural
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);

                    if(tamaño_destino > 64)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo máximo es 64 bits, y has"
                                    ~ " pedido " ~ to!dstring(tamaño_destino) ~ "bits");
                    }

                    if(tamaño_destino < 1)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo mínimo es 1 bit, y has"
                                    ~ " pedido " ~ to!dstring(tamaño_destino) ~ "bits");
                    }

                    // si el tamaño de destino es mayor o igual, no hay problema
                    if(tamaño_destino < tamaño_origen)
                    {
                        avisa(módulo, op.posición, "op:conv - Tipo de destino menor que Tipo de origen, podrías desbordar la variable");
                    }
                    break;

                case 'e': // convertimos de natural a entero
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);

                    if(tamaño_destino > 64)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo máximo es 64 bits, y has"
                                    ~ " pedido " ~ to!dstring(tamaño_destino) ~ "bits");
                    }

                    if(tamaño_destino < 1)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo mínimo es 2 bits, y has"
                                    ~ " pedido " ~ to!dstring(tamaño_destino) ~ "bits");
                    }

                    // si el tamaño de destino es mayor o igual, no hay problema
                    if(tamaño_destino < tamaño_origen)
                    {
                        avisa(módulo, op.posición, "op:conv - Tipo de destino menor que Tipo de origen, podrías desbordar la variable.");
                    }
                    break;

                case 'r':
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);

                    // en los reales cuando se desborda se para en +/-infinito.
                    // El problema principal, no evitable, es la pérdida de
                    // precisión con números muy positivos o muy negativos.
                    // La máxima precisión se encuentra en torno al cero.

                    if(tamaño_destino > 64)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo máximo es 64 bits, y has"
                        ~ " pedido " ~ destino.tipo[1..$] ~ "bits");
                    }
                    if(tamaño_destino < 1)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo mínimo es 1 bit, y has"
                        ~ " pedido " ~ destino.tipo[1..$] ~ "bits");
                    }

                    // si el tamaño de destino es mayor o igual, no hay problema
                    if(tamaño_destino < tamaño_origen)
                    {
                        avisa(módulo, op.posición, "op:conv - Tipo de destino menor que Tipo de origen, podrías desbordar la variable.");
                    }
                    break;

                default:
                    aborta(módulo, op.posición, "op:conv - tipo desconocido");
                    break;
            }

            break;

        case 'e':
            tamaño_origen = to!uint32_t(origen.tipo[1..$]);

            switch(destino.tipo[0])
            {
                case 'n': // convertimos de natural a natural
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);

                    if(tamaño_destino > 64)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo máximo es 64 bits, y has"
                                    ~ " pedido " ~ to!dstring(tamaño_destino) ~ "bits");
                    }

                    if(tamaño_destino < 1)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo mínimo es 1 bit, y has"
                                    ~ " pedido " ~ to!dstring(tamaño_destino) ~ "bits");
                    }

                    // si el tamaño de destino es mayor o igual, no hay problema
                    if(tamaño_destino < tamaño_origen)
                    {
                        avisa(módulo, op.posición, "op:conv - Tipo de destino menor que Tipo de origen, podrías desbordar la variable.");
                    }
                    break;

                case 'e': // convertimos de natural a entero
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);

                    if(tamaño_destino > 64)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo máximo es 64 bits, y has"
                                    ~ " pedido " ~ to!dstring(tamaño_destino) ~ "bits");
                    }

                    if(tamaño_destino < 1)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo mínimo es 2 bits, y has"
                                    ~ " pedido " ~ to!dstring(tamaño_destino) ~ "bits");
                    }

                    // si el tamaño de destino es mayor o igual, no hay problema
                    if(tamaño_destino < tamaño_origen)
                    {
                        avisa(módulo, op.posición, "op:conv - Tipo de destino menor que Tipo de origen, podrías desbordar la variable.");
                    }
                    break;

                case 'r':
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);

                    // en los reales cuando se desborda se para en +/-infinito.
                    // El problema principal, no evitable, es la pérdida de
                    // precisión con números muy positivos o muy negativos.
                    // La máxima precisión se encuentra en torno al cero.

                    if(tamaño_destino > 64)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo máximo es 64 bits, y has"
                        ~ " pedido " ~ destino.tipo[1..$] ~ "bits");
                    }
                    if(tamaño_destino < 1)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo mínimo es 1 bit, y has"
                        ~ " pedido " ~ destino.tipo[1..$] ~ "bits");
                    }

                    // si el tamaño de destino es mayor o igual, no hay problema
                    if(tamaño_destino < tamaño_origen)
                    {
                        avisa(módulo, op.posición, "op:conv - Tipo de destino menor que Tipo de origen, podrías desbordar la variable.");
                    }
                    break;

                default:
                    aborta(módulo, op.posición, "op:conv - tipo desconocido");
                    break;
            }
            
            break;

        case 'r':
            tamaño_origen = to!uint32_t(origen.tipo[1..$]);

            switch(destino.tipo[0])
            {
                case 'n': // convertimos de natural a natural
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);

                    if(tamaño_destino > 64)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo máximo es 64 bits, y has"
                                    ~ " pedido " ~ to!dstring(tamaño_destino) ~ "bits");
                    }

                    if(tamaño_destino < 1)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo mínimo es 1 bit, y has"
                                    ~ " pedido " ~ to!dstring(tamaño_destino) ~ "bits");
                    }

                    // si el tamaño de destino es mayor o igual, no hay problema
                    if(tamaño_destino < tamaño_origen)
                    {
                        avisa(módulo, op.posición, "op:conv - Tipo de destino menor que Tipo de origen, podrías desbordar la variable.");
                    }
                    break;

                case 'e': // convertimos de natural a entero
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);

                    if(tamaño_destino > 64)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo máximo es 64 bits, y has"
                                    ~ " pedido " ~ to!dstring(tamaño_destino) ~ "bits");
                    }

                    if(tamaño_destino < 1)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo mínimo es 2 bits, y has"
                                    ~ " pedido " ~ to!dstring(tamaño_destino) ~ "bits");
                    }

                    // si el tamaño de destino es mayor o igual, no hay problema
                    if(tamaño_destino < tamaño_origen)
                    {
                        avisa(módulo, op.posición, "op:conv - Tipo de destino menor que Tipo de origen, podrías desbordar la variable.");
                    }
                    break;

                case 'r':
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);

                    // en los reales cuando se desborda se para en +/-infinito.
                    // El problema principal, no evitable, es la pérdida de
                    // precisión con números muy positivos o muy negativos.
                    // La máxima precisión se encuentra en torno al cero.

                    if(tamaño_destino > 64)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo máximo es 64 bits, y has"
                        ~ " pedido " ~ destino.tipo[1..$] ~ "bits");
                    }
                    if(tamaño_destino < 1)
                    {
                        aborta(módulo, op.posición, "op:conv - el tamaño del tipo mínimo es 1 bit, y has"
                        ~ " pedido " ~ destino.tipo[1..$] ~ "bits");
                    }

                    // si el tamaño de destino es mayor o igual, no hay problema
                    if(tamaño_destino < tamaño_origen)
                    {
                        avisa(módulo, op.posición, "op:conv - Tipo de destino menor que Tipo de origen, podrías desbordar la variable.");
                    }
                    break;

                default:
                    aborta(módulo, op.posición, "op:conv - tipo desconocido");
                    break;
            }
            
            break;

        default:
            aborta(módulo, op.posición, "op:conv - tipo desconocido");
            break;
    }

    // Si llego hasta aquí, devuelvo el tipo de destino
    return destino;
}

Tipo op_slt(Operación op)
{
    if(op.dato != "slt")
    {
        aborta(módulo, op.posición, "Esperaba que el código de la operación fuera 'slt'");
        return null;
    }

    // Salto incondicional
    // slt :<etiqueta>
    if(op.ramas.length == 1)
    {
        Etiqueta etiqueta = cast(Etiqueta)(op.ramas[0]);

        if(!tid_local.coge_id(etiqueta.dato).nombre)
        {
            aborta(módulo, op.posición, "op:slt - La etiqueta no existe");
        }

        return null;
    }
    // Salto condicional
    // slt n1 (<id>|<literal>) :<etiqueta>
    else if(op.ramas.length == 3)
    {
        Tipo t = cast(Tipo)(op.ramas[0]);
        bool condición = false;

        if(t is null)
        {
            aborta(módulo, op.posición, "op:slt - Tipo 'null'.\nslt [n1 (<id>|<literal>)] :<etiqueta>");
            return null;
        }
        else if(t.tipo != "n1")
        {
            aborta(módulo, op.posición, "op:slt - Tipo incorrecto. Esperaba 'n1'.\nslt [n1 (<id>|<literal>)] :<etiqueta>");
            return null;
        }

        Nodo n = op.ramas[1];
        if(n.categoría == Categoría.LITERAL)
        {
            Literal l = cast(Literal)n;
            comprueba_tipo_literal(t, l);
        }
        else if(n.categoría == Categoría.IDENTIFICADOR)
        {
            Tipo tlit;
            Nodo id = coge_identificador(n);
            if(id.categoría == Categoría.TIPO)
            {
                tlit = cast(Tipo)id;
            }
            else
            {
                aborta(módulo, n.posición, "No he podido obtener un tipo para el identificador '" ~ n.dato ~ "'");
            }

            Nodo nt1 = cast(Nodo)t;
            Nodo nt2 = cast(Nodo)tlit;

            if(!compara_árboles(&nt1, &nt2))
            {
                aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
            }
        }

        Etiqueta etiqueta = cast(Etiqueta)(op.ramas[2]);

        if(!tid_local.coge_id(etiqueta.dato).nombre)
        {
            aborta(módulo, op.posición, "op:slt - La etiqueta no existe");
        }
        
        return null;
    }

    aborta(módulo, op.posición, "slt [n1 (<id>|<literal>)] :<etiqueta>");

    return null;
}

Tipo op_phi(Operación op)
{
    aborta(módulo, op.posición, "No he implementado la operación Phi.");
    return null;
}

Tipo op_rsrva(Operación op)
{
    if(op.dato != "rsrva")
    {
        aborta(módulo, op.posición, "Esperaba que el código de la operación fuera 'rsrva'");
        return null;
    }

    if(op.ramas.length == 1)
    {
        Tipo t = cast(Tipo)(op.ramas[0]);

        return t;
    }

    aborta(módulo, op.posición, "rsrva <tipo>");
    
    return null;
}

Tipo op_lee(Operación op)
{
    if(op.dato != "lee")
    {
        aborta(módulo, op.posición, "Esperaba que el código de la operación fuera 'lee'");
        return null;
    }

    if(op.ramas.length == 3)
    {
        // Extraigo los 3 nodos hijos
        Tipo t1 = cast(Tipo)(op.ramas[0]);  // tipo
        Tipo t2 = cast(Tipo)(op.ramas[1]);  // tipo *
        Nodo n = op.ramas[2];               // dirección de memoria conteniendo tipo

        // Si 'n' es un Literal, no podemos hacer más comprobaciones
        if(n.categoría == Categoría.LITERAL)
        {
            return t1;
        }
        else if(n.categoría == Categoría.IDENTIFICADOR) // Sólo podemos comprobar que el identificador existe
        {
            if(!tid_local.lee_id((cast(Identificador)n).nombre).nombre)
            {
                aborta(módulo, op.posición, "op:lee - El identificador no existe.");
                return null;
            }

            return t1;
        }
    }

    aborta(módulo, op.posición, "lee <tipo>, <tipo> * ( <id>|<literal> )");
    return null;
}

Tipo op_guarda(Operación op)
{
    if(op.dato != "guarda")
    {
        aborta(módulo, op.posición, "Esperaba que el código de la operación fuera 'guarda'");
        return null;
    }

    if(op.ramas.length == 4)
    {
        Tipo t1 = cast(Tipo)(op.ramas[0]);  // tipo
        Tipo t2 = cast(Tipo)(op.ramas[2]);  // tipo *
        Nodo n1 = op.ramas[1];              // valor (Literal / Identificador)
        Nodo n2 = op.ramas[3];              // dirección de memoria (Literal / Identificador)

        if(n1.categoría == Categoría.LITERAL)
        {
            Literal l1 = cast(Literal)n1;
            comprueba_tipo_literal(t1, l1); // Aborta si incorrecto

            if(n2.categoría == Categoría.LITERAL)
            {
                return null;
            }
            else if(n2.categoría == Categoría.IDENTIFICADOR)
            {
                if(!tid_local.lee_id((cast(Identificador)n2).nombre).nombre)
                {
                    aborta(módulo, op.posición, "op:guarda - El identificador no existe.");
                    return null;
                }

                return null;
            }
        }
        else if(n1.categoría == Categoría.IDENTIFICADOR) // Sólo podemos comprobar que el identificador existe
        {
            if(!tid_local.lee_id((cast(Identificador)n1).nombre).nombre)
            {
                aborta(módulo, op.posición, "op:guarda - El identificador no existe.");
                return null;
            }

            Tipo tlit;
            Nodo id = coge_identificador(n1);
            if(id.categoría == Categoría.TIPO)
            {
                tlit = cast(Tipo)id;
            }
            else
            {
                aborta(módulo, n1.posición, "No he podido obtener un tipo para el identificador '" ~ n1.dato ~ "'");
            }

            Nodo nt1 = cast(Nodo)t1;
            Nodo nt2 = cast(Nodo)tlit;

            if(!compara_árboles(&nt1, &nt2))
            {
                aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
            }

            if(n2.categoría == Categoría.LITERAL)
            {
                return null;
            }
            else if(n2.categoría == Categoría.IDENTIFICADOR)
            {
                if(!tid_local.coge_id((cast(Identificador)n2).nombre).nombre)
                {
                    aborta(módulo, op.posición, "op:guarda - El identificador no existe.");
                    return null;
                }

                return null;
            }
        }
    }

    aborta(módulo, op.posición, "guarda <tipo> '(' <id>|<literal> ')', <tipo>* '(' <id>|<literal> ')'");
    return null;
}

Tipo op_leeval(Operación op)
{
    if(op.dato != "leeval")
    {
        aborta(módulo, op.posición, "Esperaba que el código de la operación fuera 'leeval'");
        return null;
    }

    if(op.ramas.length == 3)
    {
        Tipo tip = cast(Tipo)(op.ramas[0]); // Tipo
        Nodo ntip = cast(Nodo)tip;
        Nodo var = op.ramas[1];             // Valor
        Tipo tvar;
        Nodo idx = op.ramas[2];             // Índice
        Tipo tidx;
        uint índice;

        if(var.categoría == Categoría.LITERAL)
        {
            if(!tip.vector && !tip.estructura)
            {
                aborta(módulo, op.posición, "op:leeval trabaja con estructuras o vectores.");
                return null;
            }

            Literal l = cast(Literal)var;
            comprueba_tipo_literal(tip, l);
        }
        else if(var.categoría == Categoría.IDENTIFICADOR)
        {
            Nodo ntvar = coge_identificador(var);
            if(ntvar.categoría == Categoría.TIPO)
            {
                tvar = cast(Tipo)ntvar;
            }
            else
            {
                aborta(módulo, var.posición, "No he podido obtener un tipo para el identificador '" ~ var.dato ~ "'");
            }

            if(!tvar.vector && !tvar.estructura)
            {
                aborta(módulo, op.posición, "op:leeval trabaja con estructuras o vectores.");
                return null;
            }

            if(!compara_árboles(&ntip, &ntvar))
            {
                aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
                return null;
            }
        }
        else
        {
            aborta(módulo, op.posición, "leeval <tipo-compuesto> <literal/identificador>, <índice>");
            return null;
        }

        if(tvar.vector)
        {
            if(idx.categoría == Categoría.LITERAL)
            {
                índice = to!uint(idx.dato);
                if(índice > to!uint(tvar.elementos))
                {
                    aborta(módulo, op.posición, "El vector no tiene " ~ to!dstring(índice) ~ " elementos.");
                }

                return cast(Tipo)(tvar.ramas[0]);
            }
            else if(idx.categoría == Categoría.IDENTIFICADOR)
            {
                Nodo id = coge_identificador(idx);
                if(id.categoría == Categoría.TIPO)
                {
                    tidx = cast(Tipo)id;
                }
                else
                {
                    aborta(módulo, idx.posición, "No he podido obtener un tipo para el identificador '" ~ idx.dato ~ "'");
                }

                if(!tipo_natural(tidx))
                {
                    aborta(módulo, op.posición, "El índice no es un Tipo Natural.");
                }

                return cast(Tipo)(tvar.ramas[0]);
            }
            else
            {
                aborta(módulo, op.posición, "leeval <tipo-compuesto> <literal/identificador>, <índice>");
                return null;
            }
        }
        else if(tvar.estructura)
        {
            if(idx.categoría == Categoría.LITERAL)
            {
                índice = to!uint(idx.dato);
                if(índice > to!uint(tvar.elementos))
                {
                    aborta(módulo, op.posición, "La estructura no tiene " ~ to!dstring(índice) ~ " elementos.");
                }

                return cast(Tipo)(tvar.ramas[índice]);
            }
            else if(idx.categoría == Categoría.IDENTIFICADOR)
            {
                aborta(módulo, op.posición, "Al evaluar estructuras, el índice debe conocerse en tiempo de compilación.");
            }
            else
            {
                aborta(módulo, op.posición, "leeval <tipo-compuesto> <literal/identificador>, <índice>");
                return null;
            }
        }
    }

    aborta(módulo, op.posición, "leeval <tipo_vector> <literal>, <índice>");
    return null;
}

Tipo op_ponval(Operación op)
{
    if(op.dato != "ponval")
    {
        aborta(módulo, op.posición, "Esperaba que el código de la operación fuera 'ponval'");
        return null;
    }

    if(op.ramas.length == 5)
    {
        Tipo tip1  = cast(Tipo)(op.ramas[0]);   // Tipo1
        Nodo ntip1 = cast(Nodo)tip1;
        Nodo var   = op.ramas[1];               // Variable compuesta (lit/id)
        Tipo tvar;
        Nodo ntvar;

        Tipo tip2  = cast(Tipo)(op.ramas[2]);   // Tipo2
        Nodo ntip2 = cast(Nodo)tip2;
        Nodo val   = op.ramas[4];               // Valor (lit/id)
        Tipo tval;
        Nodo ntval;
        
        Nodo idx = op.ramas[2];                 // Índice (lit/id)
        Tipo tidx;
        uint índice;

        // Primero comprueba concordancia de tipo entre tip1 y var.
        if(var.categoría == Categoría.LITERAL)
        {
            Literal lvar = cast(Literal)var;
            comprueba_tipo_literal(tip1, lvar); // continúa si correcto
        }
        else if(var.categoría == Categoría.IDENTIFICADOR)
        {
            ntvar = coge_identificador(var);
            if(ntvar.categoría == Categoría.TIPO)
            {
                tvar = cast(Tipo)ntvar;
            }
            else
            {
                aborta(módulo, var.posición, "No he podido obtener un tipo para el identificador '" ~ var.dato ~ "'");
            }

            if(!compara_árboles(&ntip1, &ntvar))
            {
                aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
                return null;
            }
        }
        else
        {
            aborta(módulo, op.posición, "ponval <tipo_vector> <literal_vector>, <tipo> <literal>, <índice>");
            return null;
        }

        // Segundo comprueba concordancia de tipo entre tip2 y val.
        if(val.categoría == Categoría.LITERAL)
        {
            Literal lval = cast(Literal)val;
            comprueba_tipo_literal(tip2, lval); // continúa si correcto
        }
        else if(val.categoría == Categoría.IDENTIFICADOR)
        {
            ntvar = coge_identificador(var);
            if(ntvar.categoría == Categoría.TIPO)
            {
                tvar = cast(Tipo)ntvar;
            }
            else
            {
                aborta(módulo, var.posición, "No he podido obtener un tipo para el identificador '" ~ var.dato ~ "'");
            }

            if(!compara_árboles(&ntip2, &ntval))
            {
                aborta(módulo, op.posición, "El tipo declarado y el tipo del identificador no coinciden.");
                return null;
            }
        }
        else
        {
            aborta(módulo, op.posición, "ponval <tipo_vector> <literal_vector>, <tipo> <literal>, <índice>");
            return null;
        }

        // Después comprueba que tip1 tiene suficientes elementos para que
        // índice no ocasione un desbordamiento (sólo si índice es Literal)
        if(idx.categoría == Categoría.LITERAL)
        {
            índice = to!uint(idx.dato);

            if(índice > to!uint(tip1.elementos))
            {
                aborta(módulo, op.posición, "El índice es demasiado grande. Desbordará la memoria reservada.");
            }
        }

        // Finalmente comprueba que el tipo de var[índice] coincide con el de val
        if(tip1.vector)
        {
            // Si trabajo con un vector, tip2 siempre será el mismo
            // Comparo tip2 con tip1[0]
            compara_árboles(&(tip1.ramas[0]), &ntip2); // Sólo continúa si es correcto

            return tip1; // Devuelve el tipo compuesto
        }
        else if(tip1.estructura)
        {
            // Si trabajo con una estructura, tip2 depende del índice
            // Debo conocer el valor del índice durante la compilación
            // índice debe ser un Literal
            if(idx.categoría == Categoría.LITERAL)
            {
                // Comparo tip2 con tip1[índice]
                índice = to!uint(idx.dato);
                compara_árboles(&(tip1.ramas[índice]), &ntip2); // Sólo continúa si es correcto
            }
            else
            {
                aborta(módulo, op.posición, "Al trabajar con estructuras, el índice debe ser conocido en tiempo de compilación.");
                return null;
            }

            return tip1; // Devuelve el tipo compuesto
        }
        else
        {
            aborta(módulo, op.posición, "el tipo debe ser un vector o una estructura.");
            return null;
        }
    }

    return null;
}