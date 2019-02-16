module gcf;

dstring módulo = "GCF (Grafo de Control de Flujo).d";

import apoyo;
import arbol;
import std.conv;
import std.stdio;

// Creo una tabla desechable para los identificadores.
TablaIdentificadores tid_local;

// Modifica cada función para incluir un Grafo de Control de Flujo
void genera_grafos_control_flujo(ref TablaIdentificadores tid)
{
    // Genera un GCF para cada función definida en los identificadores globales...

    // recorre los id's globales
    foreach(ref EntradaTablaIdentificadores eid; tid.tabla)
    {
        // en cada iteración, eid contiene una entrada con un id global

        // Analiza sólo los id's que ya están definidos
        if(eid.definido)
        {
            Nodo def = eid.definición;

            // Analiza sólo las definiciones de funciones
            if(def.categoría == Categoría.DEFINE_FUNCIÓN)
            {
                auto deffn = cast(DefineFunción)def;

                charlatánln();
                charlatánln("Genero Grafo de Control de Flujo para " ~ deffn.nombre ~ "()");

                // Genera el Grafo de Control de Flujo para esta función
                Bloque bloque = crea_GCF(def);

                if(def.ramas.length == 2)
                {
                    if(def.ramas[1].categoría == Categoría.BLOQUE)
                    {
                        def.ramas[1] = bloque;
                    }
                    else
                    {
                        error(módulo, def.posición, "No encuentro el Bloque en la definición de esta función");
                        muestra_árbol(def);
                        aborta(módulo, def.posición, "Aborto");
                    }
                }
                else if(def.ramas.length == 1)
                {
                    if(def.ramas[0].categoría == Categoría.BLOQUE)
                    {
                        def.ramas[0] = bloque;
                    }
                    else
                    {
                        error(módulo, def.posición, "No encuentro el Bloque en la definición de esta función");
                        muestra_árbol(def);
                        aborta(módulo, def.posición, "Aborto");
                    }
                }
                else
                {
                        error(módulo, def.posición, "No encuentro el Bloque en la definición de esta función");
                        muestra_árbol(def);
                        aborta(módulo, def.posición, "Aborto");
                }

                eid.definición = def;
            }
        }
    }
}

Bloque crea_GCF(Nodo deffn)
{
    Bloque bloque = obtén_bloque(deffn);

    //writeln();
    //writeln();
    //writeln((cast(DefineFunción)deffn).nombre ~ "()");
    //writeln();

    tid_local = new TablaIdentificadores(deffn);

    obtén_etiquetas(cast(Nodo)bloque, tid_local);

    Bloque bloqueVértices = obtén_vértices(bloque);

    obtén_aristas(bloqueVértices);

    //muestra_árbol(bloqueVértices);

    return bloqueVértices;
}


Bloque obtén_vértices(Bloque bloque)
{
    Bloque resultado = new Bloque();

    Vértice grupo = new Vértice();

    //recorre las ramas del bloque
    for(int i = 0, j = 0; i<bloque.ramas.length; i++, j++)
    {
        // Buscar nueva etiqueta
        if(bloque.ramas[i].etiqueta.length > 0)
        {
            if(j == 0)
            {
                grupo.etiqueta = bloque.ramas[i].etiqueta;
            }
            else if(j > 0)
            {
                dstring destino = bloque.ramas[i].etiqueta;
                grupo.salto = destino;
                resultado.ramas ~= grupo;
                grupo = new Vértice();
                j = 0;
                grupo.etiqueta = bloque.ramas[i].etiqueta;
            }
        }

        // Comprobar si la operación ejecutada ha sido un op:slt.
        Nodo n = bloque.ramas[i];
        if(n.categoría == Categoría.OPERACIÓN)
        {
            Operación op = cast(Operación)n;
            if(op.dato == "slt")
            {
                dstring destino = obtén_destino_de_salto(op);
                grupo.salto_condicional = salto_condicional(op);
                grupo.salto = destino;
                grupo.ramas ~= bloque.ramas[i];
                resultado.ramas ~= grupo;
                grupo = new Vértice();
                j = -1;
            }
            else
            {
                grupo.ramas ~= bloque.ramas[i];
            }
        }
        else
        {
            grupo.ramas ~= bloque.ramas[i];
        }
    }
    
    resultado.ramas ~= grupo;

    for(int i = 0; i < resultado.ramas.length; i++)
    {
        (cast(Vértice)(resultado.ramas[i])).número_vértice = i;
    }

    return resultado;
}

bool salto_condicional(Operación op)
{
    if(op.ramas.length == 1) // salto incondicional
    {
        return false;
    }
    else if(op.ramas.length == 3) // salto condicional
    {
        return true;
    }

    assert(0);
}

dstring obtén_destino_de_salto(Operación op)
{
    if(op.ramas.length == 1) // salto incondicional
    {
        return op.ramas[0].dato;
    }
    else if(op.ramas.length == 3) // salto condicional
    {
        return op.ramas[2].dato;
    }

    assert(0);
}

void obtén_aristas(ref Bloque bloque)
{
    for(int i = 0; i < bloque.ramas.length; i++)
    {
        if((cast(Vértice)(bloque.ramas[i])).salto.length > 0)
        {
            dstring destino = (cast(Vértice)(bloque.ramas[i])).salto;
            for(int j = 0; j < bloque.ramas.length; j++)
            {
                dstring etiqueta = (cast(Vértice)(bloque.ramas[j])).etiqueta;
                if(etiqueta == destino)
                {
                    añade_arista(bloque, i, j);
                    break;
                }
            }

            if((cast(Vértice)(bloque.ramas[i])).salto_condicional)
            {
                añade_arista(bloque, i, i + 1);
            }
        }
        else if((cast(Vértice)(bloque.ramas[i])).salto.length == 0)
        {
            if( (i+1) < bloque.ramas.length)
            {
                añade_arista(bloque, i, i + 1);
            }
        }
        else
        {
            assert(0);
        }
    }
}

void añade_arista(ref Bloque bloque, int entrada, int salida)
{
    Arista arista = new Arista();

    Nodo vértice_entrada = bloque.ramas[entrada];
    Nodo vértice_salida = bloque.ramas[salida];
    arista.entrada = cast(Vértice)vértice_entrada;
    arista.salida = cast(Vértice)vértice_salida;

    (cast(Vértice)(bloque.ramas[entrada])).añade_arista_salida(arista);
    (cast(Vértice)(bloque.ramas[salida])).añade_arista_entrada(arista);
}