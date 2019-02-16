module longevidad;

dstring módulo = "Longevidad.d";

import apoyo;
import arbol;
import std.algorithm.mutation;
import std.conv;
import std.stdio;

bool cambio_calculando_longevidad;

Longevidad[][] obtén_longevidad(ref Nodo nodo)
{
    cambio_calculando_longevidad = false;

    if(nodo.categoría != Categoría.DEFINE_FUNCIÓN)
    {
        return null;
    }

    Longevidad[][] longevidad = obtén_longevidad_función(nodo);

    return longevidad;
}

// El resultado del análisis de longevidad será un array de N structs Longevidad
// N es igual al nº de instrucciones + 1
// Cada struct Longevidad contiene las variables usadas y la variable definida

struct Longevidad
{
    dstring     variable_definida;
    dstring[]   variables_vivas;
}

Longevidad[][] prepara_estructura_longevidad(ref Bloque bloque)
{
    Longevidad[][] longevidad;

    foreach(ref vértice; bloque.ramas)
    {
        Longevidad[] longevidad_vértice = crea_longevidad_vértice(vértice);

        longevidad ~= longevidad_vértice;
    }

    return longevidad;
}

Longevidad[] crea_longevidad_vértice(ref Nodo nodo)
{
    Longevidad[] longevidad;

    for(int i = 0; i < (nodo.ramas.length + 1); i++)
    {
        Longevidad l;
        longevidad ~= l;
    }

    return longevidad;
}

Longevidad[][] obtén_longevidad_función(ref Nodo nodo)
{
    Bloque bloque = obtén_bloque(nodo);

    Longevidad[][] longevidad = prepara_estructura_longevidad(bloque);

    do {
        cambio_calculando_longevidad = false;

        for(int i = 0; i < bloque.ramas.length; i++)
        {
            obtén_longevidad_vértice(bloque.ramas[i], longevidad[i], false);
        }
    } while(cambio_calculando_longevidad);

    return longevidad;
}

void obtén_longevidad_vértice(ref Nodo nodo, ref Longevidad[] longevidad, bool verborrea)
{
    if(verborrea) writeln("VÉRTICE [" ~ to!dstring(nodo.ramas.length) ~ " ramas]");

    // Navega las instrucciones en orden inverso obteniendo, para cada
    // instrucción, la lista de variables empleadas (variables_vivas)
    // y la variable definida (variable_definida)
    for(int i = nodo.ramas.length - 1; i >= 0; i--)
    {
        bool he_cambiado = false;
        
        if(verborrea) write("RAMA #" ~ to!dstring(i));
        
        if(nodo.ramas[i].categoría == Categoría.ASIGNACIÓN)
        {
            if(verborrea)
            {
                write("  As :: ");

                write("[ ");
                foreach(v; longevidad[i].variables_vivas)
                {
                    write(v);
                    write(" ");
                }
                write("] ");
            }
            
            // Se va a definir una variable. En el subárbol, el identificador es
            // el nodo en la primera rama.
            Nodo asignación = nodo.ramas[i];
            Identificador id = cast(Identificador)(asignación.ramas[0]);
            dstring variable_definida = id.nombre;

            if(verborrea) write("[ -- " ~ variable_definida ~ " ] ");

            // POR COMPLETAR qué hacer con las variables recién definidas

            // A continuación, la 2ª rama contiene una operación, que debemos
            // analizar para obtener las variables empleadas (vivas)

            dstring[] variables_empleadas = obtén_variables_empleadas(asignación.ramas[1]);

            if(verborrea) 
            {
                write(" [ ++ ");
                foreach(v; variables_empleadas)
                {
                    write(v);
                    write(" ");
                }
                write("]  ==>  ");
            }
            // POR COMPLETAR qué hacer con las variables empleadas
            // Añado las variables empleadas ahora a las empleadas en la instrucción siguiente
            // Tengo cuidado de no duplicar variables
            dstring[] variables_pendientes = longevidad[i+1].variables_vivas;
            variables_pendientes ~= variables_empleadas;

            añade_variables_vivas(longevidad[i].variables_vivas, variables_pendientes, variable_definida, verborrea);
        }
        else if(nodo.ramas[i].categoría == Categoría.OPERACIÓN)
        {
            if(verborrea)
            {
                write("  Op :: ");

                write("[ ");
                foreach(v; longevidad[i].variables_vivas)
                {
                    write(v);
                    write(" ");
                }
                write("] ");
            }

            dstring[] variables_empleadas = obtén_variables_empleadas(nodo.ramas[i]);

            if(verborrea)
            {
                write("[ ++ ");
                foreach(v; variables_empleadas)
                {
                    write(v);
                    write(" ");
                }
                write("]  ==>  ");
            }

            // Qué hacer con las variables empleadas
            // Añado las variables empleadas ahora a las empleadas en la instrucción siguiente
            // Tengo cuidado de no duplicar variables
            dstring[] variables_pendientes = longevidad[i+1].variables_vivas;
            variables_pendientes ~= variables_empleadas;

            añade_variables_vivas(longevidad[i].variables_vivas, variables_pendientes, null, verborrea);
        }
        else
        {
            assert(0);
        }
    }
}

dstring[] obtén_variables_empleadas(ref Nodo nodo)
{
    dstring[] variables_vivas;

    if((nodo.categoría != Categoría.OPERACIÓN) && (nodo.categoría != Categoría.LLAMA_FUNCIÓN))
    {
        aborta(módulo, nodo.posición, "El nodo que has pasado no es válido");
    }

    foreach(argumento; nodo.ramas)
    {
        if(argumento.categoría == Categoría.IDENTIFICADOR)
        {
            Identificador id = cast(Identificador)argumento;
            variables_vivas ~= id.nombre;
        }
        else if(argumento.categoría == Categoría.LLAMA_FUNCIÓN)
        {
            return obtén_variables_empleadas(argumento);
        }
    }

    return variables_vivas;
}

bool añade_variables_vivas(ref dstring[] lista_previa, dstring[] nueva_lista, dstring definición, bool verborrea)
{
    bool he_cambiado = false;

    // 1.- INCLUYO VARIABLES NUEVAS
    // Para todas las variables en la nueva_lista
    foreach(var; nueva_lista)
    {
        // Comprueba que previamente no estaban ya incluidas en la lista_previa
        bool incluida = false;
        foreach(var_previa; lista_previa)
        {
            if(var == var_previa)
            {
                incluida = true;
                break;
            }
        }

        // Sólo si todavía no estaba incluida
        if(!incluida)
        {
            if((definición is null) || (var != definición))
            {
                lista_previa ~= var;
                cambio_calculando_longevidad = true;
                he_cambiado = true;
            }
        }
    }
    
    if(verborrea)
    {
        write("[ ");
        foreach(v; lista_previa)
        {
            write(v);
            write(" ");
        }
        write("]");
        if(he_cambiado)
        {
            write(" #################");
        }
        writeln();
    }

    return he_cambiado;
}