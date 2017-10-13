module interprete;

import apoyo;
import arbol;
import std.conv;
import std.math;
import std.stdint;
import std.stdio;

// Tabla de identificadores que se usa en la ejecución/interpretación.
TablaIdentificadores tid;

Literal analiza(Nodo n)
{
    charlatánln("Fase de Interpretación.");
    obtén_identificadores_globales(n);

	charlatánln();

    Literal[] args;
    args ~= new Literal();
    args[0].tipo = "r32";
    args[0].dato = "3.14159";
    
    Bloque bloque = prepara_función("inicio", args);

    obtén_etiquetas(bloque);

    Nodo retorno = interpreta(bloque);

    if(!declFunc_retorno_correcto("inicio", retorno))
    {
        aborta("El tipo de retorno no coincide con la declaración de inicio()");
    }

    if(retorno is null)
    {
        return null;
    }
    else
    {
        return cast(Literal)retorno;
    }
}

// el tipo del retorno coincide con la declaración de la función
bool declFunc_retorno_correcto(dstring f, Nodo n)
{
    dstring tipo;

    if(n is null)
    {
        // asumo que es el resultado de una op:ret sin argumento
        // Compruebo que coincide con lo declarado previamente
        tipo = "nada";
    }
    else if(n.categoría == Categoría.LITERAL)
    {
        Literal lit = cast(Literal)n;
        tipo = lit.tipo;
    }
    else
    {
        // Error:
        aborta("Me has dado algo diferente a 'null' o un literal");
    }

    if(tid.lee_id(f).nombre is null)
    {
        aborta("No has declarado la función '" ~ f ~ "()'.");
    }

    EntradaTablaIdentificadores eid = tid.lee_id(f);
    // eid: dstring nombre, bool declarado, Nodo declaración, bool definido, Nodo definición;

    if(!eid.definido)
    {
        aborta("No has definido la función '" ~ f ~ "()'.");
    }

    // Obtén el Nodo de la definición
    DefineFunción def_func = cast(DefineFunción)eid.definición;

    return def_func.retorno == tipo;
}

void obtén_etiquetas(Nodo n)
{
    if(n)
    {
        tid.define_identificador(":", null, null);

        for(int i = 0; i < n.ramas.length; i++)
        {
            if(n.ramas[i].etiqueta.length > 0)
            {
                auto lit = new Literal();
                lit.dato = to!dstring(i-1);
                lit.tipo = "nada";

                if(tid.define_identificador(n.ramas[i].etiqueta, null, lit))
                {
                    charlatánln("ETIQUETA: " ~ tid.lee_id(n.ramas[i].etiqueta).nombre);
                }
            }
        }
    }
}

void obtén_identificadores_globales(Nodo n)
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
            obtén_identificadores_globales(n.ramas[i]);
        }
    }
}

Bloque prepara_función(dstring fid, Literal[] args)
{
    charlatánln("Ejecuta '" ~ fid ~ "()'.");
    
    if(tid.lee_id(fid).nombre is null)
    {
        aborta("No has declarado la función '" ~ fid ~ "()'.");
    }

    EntradaTablaIdentificadores eid = tid.lee_id(fid);
    // eid: dstring nombre, bool declarado, Nodo declaración, bool definido, Nodo definición;

    if(!eid.definido)
    {
        aborta("No has definido la función '" ~ fid ~ "()'.");
    }

    // Obtén el Nodo de la definición
    DefineFunción def_func = cast(DefineFunción)eid.definición;

    // Crea y configura la tabla de identificadores de la función
    auto tid_func = new TablaIdentificadores(tid, def_func);
    tid_func.dueño = def_func;

    // Establece la tabla de ids de @inicio() como la tid vigente.
    tid = tid_func;

    // Declara los argumentos de @inicio().
    charlatánln("Declara los argumentos de '" ~ fid ~ "()'.");
    declara_argumentos(def_func);

    // Define los argumentos de la función
    charlatánln("Define los argumentos de '" ~ fid ~ "()'.");
    
    foreach(arg; args)
    {
        arg.línea = def_func.línea;
    }

    define_argumentos(def_func, args);

    //paso 2.2: obtén el bloque de la función, para poder ejecutarlo.
    Bloque bloque = obtén_bloque(def_func);

    if(bloque is null)
    {
        aborta("No puedo ejecutar el bloque");
    }

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

                if(tid.declara_identificador(a.nombre, a))
                {
                    charlatánln("declara " ~ tid.lee_id(a.nombre).nombre);
                }
                break;

            default: break;
        }

        int i;
        for(i = 0; i < n.ramas.length; i++)
        {
            declara_argumentos(n.ramas[i]);
        }
    }
}

void define_argumentos(Nodo n, Literal[] args)
{
    if(n)
    {
        switch(n.categoría)
        {
            case Categoría.ARGUMENTOS:
                for(int i = 0; i < n.ramas.length; i++)
                {
                    auto a = cast(Argumento)n.ramas[i];

                    if(tid.define_identificador(a.nombre, args[i], args[i]))
                    {
                        charlatánln("define " ~ tid.lee_id(a.nombre).nombre);
                    }
                }
                return;

            default:
                for(int i = 0; i < n.ramas.length; i++)
                {
                    define_argumentos(n.ramas[i], args);
                }
                break;
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

Nodo interpreta(Bloque bloque)
{
    Nodo resultado;
    //recorre las ramas del bloque de @inicio()
    for(int i = 0; i<bloque.ramas.length; i++)
    {

        // Buscar nueva etiqueta, para guardarla como 'última etiqueta'
        if(bloque.ramas[i].etiqueta.length > 0)
        {
            tid.última_etiqueta(bloque.ramas[i].etiqueta);
            if(tid.última_etiqueta().length > 0)
            {
                charlatánln("ETIQUETA: " ~ tid.última_etiqueta());
            }
        }

        resultado = interpreta_nodo(bloque.ramas[i]);
        
        if(resultado !is null)
        {
            if(resultado.categoría == Categoría.ETIQUETA)
            {
                i = cast(int)(resultado.línea);
            }
        }
    }

    // Fin de ejecución de la función:
    // Hay que eliminar la tabla de identificadores actual
    TablaIdentificadores tid_padre = tid.padre;
    tid_padre.hijo = null;
    tid = null;
    tid = tid_padre;

    return resultado;
}

Nodo interpreta_nodo(Nodo n)
{
    if(n)
    {
        switch(n.categoría)
        {
            case Categoría.LITERAL:
                return n;
                //break;

            case Categoría.IDENTIFICADOR:
                auto l = cast(Identificador)n;
                charlatán(to!dstring(l.categoría));
                charlatán(" [id:");
                charlatán(l.nombre);
                charlatán("] [línea:");
                charlatán(to!dstring(l.línea));
                charlatánln("]");
                return null;
                //break;

            case Categoría.OPERACIÓN:
                auto o = cast(Operación)n;
                return ejecuta_operación(o);
                //break;

            case Categoría.ASIGNACIÓN:
                auto a = cast(Asignación)n;

                auto id = cast(Identificador)a.ramas[0];

                auto lit = cast(Literal)interpreta_nodo(a.ramas[1]);

                if(lit is null)
                {
                    aborta("He obtenido un literal nulo");
                }

                tid.define_identificador(id.nombre, a, lit);

                info(id.nombre ~ " <= ");
                infoln(lit.tipo ~ ":" ~ lit.dato);

                return null;
                //break;

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
                return null;
                //break;

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
                return null;
                //break;

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
                return null;
                //break;

            case Categoría.BLOQUE:
                auto b = cast(Bloque)n;
                charlatán(to!dstring(b.categoría));
                charlatán(" [línea:");
                charlatán(to!dstring(b.línea));
                charlatánln("]");
                return null;
                //break;

            case Categoría.ARGUMENTOS:
                auto a = cast(Argumentos)n;
                charlatán(to!dstring(a.categoría));
                charlatán(" [línea:");
                charlatán(to!dstring(a.línea));
                charlatánln("]");
                return null;
                //break;

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
                return null;
                //break;

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
                return null;
                //break;

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
                return null;
                //break;

            case Categoría.MÓDULO:
                auto obj = cast(Módulo)n;
                charlatán(to!dstring(obj.categoría));
                charlatán(" [nombre:");
                charlatán(obj.nombre);
                charlatán("] [línea:");
                charlatán(to!dstring(obj.línea));
                charlatánln("]");
                return null;
                //break;

            default:
                return null;
                //break;
        }
    }

    return null;
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
        Nodo l = (tid.lee_id(id.nombre).valor);
        if(l.categoría == Categoría.LITERAL)
        {
            lit = cast(Literal)l;
        }
    }

    return lit;
}

Nodo ejecuta_operación(Operación op)
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

        default:
            break;
    }

    return null;
}

Literal op_ret(Operación op)
{
    if(tid.última_etiqueta().length > 0)
    {
        charlatánln("ETIQUETA: " ~ tid.última_etiqueta());
    }
    else
    {
        infoln("No ha llegado a declararse ninguna etiqueta");
    }

    if(op.dato != "ret")
    {
        aborta("Esperaba que el código de la operación fuera 'ret'");
        return null;
    }

    if(op.ramas.length == 2)
    {
        // ret <tipo> (<literal>|<id>);
        Tipo t = cast(Tipo)(op.ramas[0]);
        Literal lit = lee_argumento(op.ramas[1]);
        infoln("op: ret " ~ t.tipo ~ " " ~ lit.dato ~ " [" ~ lit.dato ~ "]");
        return lit;
    }
    else if(op.ramas.length == 0)
    {
        // ret;
        infoln("op: ret");
        return null;
    }
    else
    {
        aborta("Esperaba que 'ret' tuviera uno o ningún argumento");
        return null;
    }
}

Literal op_sum(Operación op)
{
    if(op.dato != "sum")
    {
        aborta("Esperaba que el código de la operación fuera 'sum'");
        return null;
    }

    if(op.ramas.length != 3)
    {
        aborta("sum <tipo> <arg1>, <arg2>");
        return null;
    }

    Nodo n;
    Tipo t = cast(Tipo)(op.ramas[0]);
    Literal lit0, lit1;
    
    n = op.ramas[1];
    lit0 = lee_argumento(n);
    
    n = op.ramas[2];
    lit1 = lee_argumento(n);

    if((lit0 is null) || (lit1 is null))
    {
        return null;
    }

    switch(t.tipo[0])
    {
        case 'e': //entero
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 2) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            int64_t resultado;
            int64_t e0, e1;
            
            e0 = to!int64_t(lit0.dato);
            e1 = to!int64_t(lit1.dato);

            resultado = e0 + e1;

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: sum " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e0)
                  ~ ", " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'n': //natural
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 1) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            uint64_t resultado;
            uint64_t n0, n1;
            
            n0 = to!uint64_t(lit0.dato);
            n1 = to!uint64_t(lit1.dato);

            resultado = n0 + n1;

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: sum " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n0)
                  ~ ", " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'r': //real
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 16) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            double resultado;
            double r0, r1;
            
            r0 = to!double(lit0.dato);
            r1 = to!double(lit1.dato);

            resultado = r0 + r1;

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: sum " ~ "r" ~ to!dstring(tamaño) ~ " " ~ to!dstring(r0)
                  ~ ", " ~ "r" ~ to!dstring(tamaño) ~ " " ~ to!dstring(r1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        default:
            break;
    }

    

    return lit0;
}

Literal op_res(Operación op)
{
    if(op.dato != "res")
    {
        aborta("Esperaba que el código de la operación fuera 'res'");
        return null;
    }

    if(op.ramas.length != 3)
    {
        aborta("res <tipo> <arg1>, <arg2>");
        return null;
    }

    Nodo n;
    Tipo t = cast(Tipo)(op.ramas[0]);
    Literal lit0, lit1;
    
    n = op.ramas[1];
    lit0 = lee_argumento(n);
    
    n = op.ramas[2];
    lit1 = lee_argumento(n);

    if((lit0 is null) || (lit1 is null))
    {
        return null;
    }

    switch(t.tipo[0])
    {
        case 'e': //entero
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 2) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            int64_t resultado;
            int64_t e0, e1;
            
            e0 = to!int64_t(lit0.dato);
            e1 = to!int64_t(lit1.dato);

            resultado = e0 - e1;

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: res " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e0)
                  ~ ", " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'n': //natural
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 1) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            uint64_t resultado;
            uint64_t n0, n1;
            
            n0 = to!uint64_t(lit0.dato);
            n1 = to!uint64_t(lit1.dato);

            resultado = n0 - n1;

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: res " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n0)
                  ~ ", " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'r': //real
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 16) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            double resultado;
            double r0, r1;
            
            r0 = to!double(lit0.dato);
            r1 = to!double(lit1.dato);

            resultado = r0 - r1;

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: res " ~ "r" ~ to!dstring(tamaño) ~ " " ~ to!dstring(r0)
                  ~ ", " ~ "r" ~ to!dstring(tamaño) ~ " " ~ to!dstring(r1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        default:
            break;
    }

    

    return lit0;
}

Literal op_mul(Operación op)
{
    if(op.dato != "mul")
    {
        aborta("Esperaba que el código de la operación fuera 'mul'");
        return null;
    }

    if(op.ramas.length != 3)
    {
        aborta("mul <tipo> <arg1>, <arg2>");
        return null;
    }

    Nodo n;
    Tipo t = cast(Tipo)(op.ramas[0]);
    Literal lit0, lit1;
    
    n = op.ramas[1];
    lit0 = lee_argumento(n);
    
    n = op.ramas[2];
    lit1 = lee_argumento(n);

    if((lit0 is null) || (lit1 is null))
    {
        return null;
    }

    switch(t.tipo[0])
    {
        case 'e': //entero
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 2) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            int64_t resultado;
            int64_t e0, e1;
            
            e0 = to!int64_t(lit0.dato);
            e1 = to!int64_t(lit1.dato);

            resultado = e0 * e1;

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: mul " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e0)
                  ~ ", " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'n': //natural
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 1) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            uint64_t resultado;
            uint64_t n0, n1;
            
            n0 = to!uint64_t(lit0.dato);
            n1 = to!uint64_t(lit1.dato);

            resultado = n0 * n1;

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: mul " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n0)
                  ~ ", " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'r': //real
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 16) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            double resultado;
            double r0, r1;
            
            r0 = to!double(lit0.dato);
            r1 = to!double(lit1.dato);

            resultado = r0 * r1;

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: mul " ~ "r" ~ to!dstring(tamaño) ~ " " ~ to!dstring(r0)
                  ~ ", " ~ "r" ~ to!dstring(tamaño) ~ " " ~ to!dstring(r1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        default:
            break;
    }

    

    return lit0;
}

Literal op_div(Operación op)
{
    if(op.dato != "div")
    {
        aborta("Esperaba que el código de la operación fuera 'div'");
        return null;
    }

    if(op.ramas.length != 3)
    {
        aborta("div <tipo> <arg1>, <arg2>");
        return null;
    }

    Nodo n;
    Tipo t = cast(Tipo)(op.ramas[0]);
    Literal lit0, lit1;
    
    n = op.ramas[1];
    lit0 = lee_argumento(n);
    
    n = op.ramas[2];
    lit1 = lee_argumento(n);

    if((lit0 is null) || (lit1 is null))
    {
        return null;
    }

    switch(t.tipo[0])
    {
        case 'e': //entero
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 2) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            int64_t resultado;
            int64_t e0, e1;
            
            e0 = to!int64_t(lit0.dato);
            e1 = to!int64_t(lit1.dato);

            resultado = e0 / e1;

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: div " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e0)
                  ~ ", " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'n': //natural
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 1) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            uint64_t resultado;
            uint64_t n0, n1;
            
            n0 = to!uint64_t(lit0.dato);
            n1 = to!uint64_t(lit1.dato);

            resultado = n0 / n1;

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: div " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n0)
                  ~ ", " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'r': //real
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 16) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            double resultado;
            double r0, r1;
            
            r0 = to!double(lit0.dato);
            r1 = to!double(lit1.dato);

            resultado = r0 / r1;

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: div " ~ "r" ~ to!dstring(tamaño) ~ " " ~ to!dstring(r0)
                  ~ ", " ~ "r" ~ to!dstring(tamaño) ~ " " ~ to!dstring(r1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        default:
            break;
    }

    

    return lit0;
}

Literal op_llama(Operación op)
{
    if(op.dato != "llama")
    {
        aborta("Esperaba que el código de la operación fuera 'llama'");
        return null;
    }

    if(op.ramas.length != 1)
    {
        aborta("Esperaba que la operación 'llama' se acompañara de una función");
        return null;
    }

    LlamaFunción f = cast(LlamaFunción)op.ramas[0];

    info("op: llama " ~ f.tipo ~ " " ~ f.nombre ~ "(");

    Literal[] args;
    
    foreach(Nodo n; f.ramas)
    {
        Literal l = lee_argumento(n);
        args ~= l;
        info(l.tipo ~ " " ~ l.dato ~ " ");
    }

    infoln(")");
    
    Bloque bloque = prepara_función(f.nombre, args);

    Nodo n = interpreta(bloque);

    if(!declFunc_retorno_correcto(f.nombre, n))
    {
        aborta("El tipo de retorno no coincide con la declaración de inicio()");
    }

    if(n is null)
    {
        return null;
    }
    else
    {
        return cast(Literal)n;
    }
}

// op:cmp [OPCMP, TIPO, LITERAL|IDENTIFICADOR, LITERAL|IDENTIFICADOR]
Literal op_cmp(Operación op)
{
    if(op.dato != "cmp")
    {
        aborta("Esperaba que el código de la operación fuera 'cmp'");
        return null;
    }

    if(op.ramas.length != 4)
    {
        aborta("cmp <comparación> <tipo> (<literal>|<id>), (<literal>|<id>)");
        return null;
    }

    auto r = op.ramas[0];

    dstring comparación = r.dato;

    dstring s = comparación;

    if(   (s == "ig") // igual
        | (s == "dsig") // diferente
        | (s == "ma") // mayor
        | (s == "me") // menor
        | (s == "maig") // mayor o igual
        | (s == "meig") // menor o igual
        )
    {}
    else
    {
        aborta("El comando de comparación es incorrecto");
    }

    Nodo n;
    Tipo t;
    Literal lit0, lit1;
    bool resultado;

    t = cast(Tipo)(op.ramas[1]);
    
    n = op.ramas[2];
    lit0 = lee_argumento(n);
    
    n = op.ramas[3];
    lit1 = lee_argumento(n);

    if((lit0 is null) || (lit1 is null))
    {
        aborta("Los argumentos son incorrectos");
    }

    switch(t.tipo[0])
    {
        case 'e': //entero
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 2) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            int64_t var0, var1;
            
            var0 = to!int64_t(lit0.dato);
            var1 = to!int64_t(lit1.dato);

            if(comparación == "ig")
            {
                // igual que...
                resultado = var0 == var1;
            }
            else if(comparación == "dif")
            {
                // diferente a...
                resultado = var0 != var1;
            }
            else if(comparación ==  "ma")
            {
                // mayor que...
                resultado = var0 > var1;
            }
            else if(comparación ==  "me")
            {
                // menor que...
                resultado = var0 < var1;
            }
            else if(comparación ==  "mai")
            {
                // mayor o igual que...
                resultado = var0 >= var1;
            }
            else if(comparación ==  "mei")
            {
                // menor o igual que...
                resultado = var0 <= var1;
            }

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: cmp " ~ comparación ~ " e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(var0)
                  ~ ", " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(var1);

            dstring cero = to!dstring(0);
            dstring uno  = to!dstring(1);

            txt ~= " [" ~ (resultado?uno:cero) ~ "]";

            infoln(txt);

            break;

        case 'n': //natural
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 1) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            uint64_t var0, var1;
            
            var0 = to!uint64_t(lit0.dato);
            var1 = to!uint64_t(lit1.dato);

            if(comparación == "ig")
            {
                // igual que...
                resultado = var0 == var1;
            }
            else if(comparación == "dif")
            {
                // diferente a...
                resultado = var0 != var1;
            }
            else if(comparación ==  "ma")
            {
                // mayor que...
                resultado = var0 > var1;
            }
            else if(comparación ==  "me")
            {
                // menor que...
                resultado = var0 < var1;
            }
            else if(comparación ==  "mai")
            {
                // mayor o igual que...
                resultado = var0 >= var1;
            }
            else if(comparación ==  "mei")
            {
                // menor o igual que...
                resultado = var0 <= var1;
            }

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: cmp " ~ comparación ~ " n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(var0)
                  ~ ", " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(var1);

            dstring cero = to!dstring(0);
            dstring uno  = to!dstring(1);

            txt ~= " [" ~ (resultado?uno:cero) ~ "]";

            infoln(txt);

            break;

        case 'r': //real
            for(int i = 1; i < t.tipo.length; i++)
            {
                if(!esdígito(t.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(t.tipo[1..$]);

            if((tamaño < 16) || (tamaño > 64))
            {
                aborta("El tamaño del tipo se sale del rango");
                return null;
            }

            double var0, var1;
            
            var0 = to!double(lit0.dato);
            var1 = to!double(lit1.dato);

            if(comparación == "ig")
            {
                // igual que...
                resultado = var0 == var1;
            }
            else if(comparación == "dif")
            {
                // diferente a...
                resultado = var0 != var1;
            }
            else if(comparación ==  "ma")
            {
                // mayor que...
                resultado = var0 > var1;
            }
            else if(comparación ==  "me")
            {
                // menor que...
                resultado = var0 < var1;
            }
            else if(comparación ==  "mai")
            {
                // mayor o igual que...
                resultado = var0 >= var1;
            }
            else if(comparación ==  "mei")
            {
                // menor o igual que...
                resultado = var0 <= var1;
            }

            auto l = new Literal();
            l.dato = to!dstring(resultado);
            l.tipo = t.tipo;

            dstring txt;
            txt = "op: cmp " ~ comparación ~ " r" ~ to!dstring(tamaño) ~ " " ~ to!dstring(var0)
                  ~ ", " ~ "r" ~ to!dstring(tamaño) ~ " " ~ to!dstring(var1);

            dstring cero = to!dstring(0);
            dstring uno  = to!dstring(1);

            txt ~= " [" ~ (resultado?uno:cero) ~ "]";

            infoln(txt);
            break;

        default:
            break;
    }

    dstring cero = to!dstring(0);
    dstring uno  = to!dstring(1);

    dstring txt = (resultado?uno:cero);

    Literal resul = new Literal;
    resul.tipo = "n1";
    resul.dato = txt;

    return resul;
}

Literal op_conv(Operación op)
{
    // dos tipos de conversiones:
    // truncamientos y extensiones dentro del mismo tipo general:
        // conv nX nY
        // conv eX eY
        // conv rX rY
    // cambios de tipo:
        // conv nX eY
        // conv nX rY
        // conv eX nY
        // conv eX rY
        // conv rX nY
        // conv rX eY
    Tipo t = cast(Tipo)(op.ramas[0]);
    Literal origen = lee_argumento(op.ramas[1]);
    Tipo destino = new Tipo();
    destino.tipo = (cast(Tipo)(op.ramas[2])).tipo;
    Literal resultado = new Literal();
    uint32_t tamaño_origen, tamaño_destino;

    resultado.tipo = destino.tipo;

    switch(t.tipo[0])
    {
        case 'n': // convertimos desde 'natural'
            tamaño_origen = to!uint32_t(t.tipo[1..$]);

            switch(destino.tipo[0])
            {
                case 'n': // convertimos de natural a natural
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);

                    // si el tamaño de destino es mayor o igual, no hay problema
                    if(tamaño_destino >= tamaño_origen)
                    {
                        if((tamaño_destino > 0) && (tamaño_destino <= 16))
                        {
                            uint16_t res = to!uint16_t(origen.dato);
                            resultado.dato = to!dstring(res);
                        }
                        else if((tamaño_destino > 0) && (tamaño_destino <= 32))
                        {
                            uint32_t res = to!uint32_t(origen.dato);
                            resultado.dato = to!dstring(res);
                        }
                        else if((tamaño_destino > 0) && (tamaño_destino <= 64))
                        {
                            uint64_t res = to!uint64_t(origen.dato);
                            resultado.dato = to!dstring(res);
                        }
                        else
                        {
                            aborta("el tamaño del tipo máximo es 64 bits, y has"
                            ~ " pedido " ~ destino.tipo[1..$] ~ "bits");
                        }
                        
                    }
                    else // el tamaño de destino es menor. Compruebo desbordes
                    {
                        uint64_t valmaxnat;

                        if(tamaño_destino < 1)
                        {
                            aborta("El tamaño del tipo de destino es erróneo");
                        }
                        else if(tamaño_destino == 64)
                        {
                            valmaxnat = uint.max;
                        }
                        else if(tamaño_destino < 64)
                        {
                             valmaxnat = pow(2, tamaño_destino) - 1;
                        }

                        if(to!uint64_t(origen.dato) > valmaxnat)
                        {
                            aborta("Has desbordado el tipo de dato. El valor "
                            ~ "máximo del tipo destino es " ~
                            to!dstring(valmaxnat));
                        }
                        else // el valor es menor que el valor máximo para el tipo
                        {
                            if((tamaño_destino > 0) && (tamaño_destino <= 16))
                            {
                                uint16_t res = to!uint16_t(origen.dato);
                                resultado.dato = to!dstring(res);
                            }
                            else if((tamaño_destino > 0) && (tamaño_destino <= 32))
                            {
                                uint32_t res = to!uint32_t(origen.dato);
                                resultado.dato = to!dstring(res);
                            }
                            else if((tamaño_destino > 0) && (tamaño_destino <= 64))
                            {
                                uint64_t res = to!uint64_t(origen.dato);
                                resultado.dato = to!dstring(res);
                            }
                            else
                            {
                                aborta("el tamaño del tipo máximo es 64 bits, y has"
                                ~ " pedido " ~ destino.tipo[1..$] ~ " bits");
                            }
                        }
                    }
                    break;

                case 'e': // convertimos de natural a entero
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);
                    
                    // los enteros necesitan un bit extra para guardar el signo
                    // por tanto, un natural puede convertirse a un entero sin
                    // problemas de desborde si el entero tiene más bits.
                    if(tamaño_destino > tamaño_origen)
                    {
                        if((tamaño_destino > 1) && (tamaño_destino <= 16))
                        {
                            int16_t res = to!int16_t(origen.dato);
                            resultado.dato = to!dstring(res);
                        }
                        else if((tamaño_destino > 1) && (tamaño_destino <= 32))
                        {
                            int32_t res = to!int32_t(origen.dato);
                            resultado.dato = to!dstring(res);
                        }
                        else if((tamaño_destino > 1) && (tamaño_destino <= 64))
                        {
                            int64_t res = to!int64_t(origen.dato);
                            resultado.dato = to!dstring(res);
                        }
                        else
                        {
                            aborta("el tamaño del tipo máximo es 64 bits, y has"
                            ~ " pedido " ~ destino.tipo[1..$] ~ "bits");
                        }
                        
                    }
                    // Pueden ocurrir desbordes, tanto hacia los números
                    // positivos como hacia los negativos
                    else if(tamaño_destino > 1)
                    {
                        int64_t valmaxent;
                        int64_t valminent;
                        
                        if(tamaño_destino == 64)
                        {
                            valmaxent = int.max;
                            valminent = int.min;
                        }
                        else if(tamaño_destino < 64)
                        {
                             valmaxent = pow(2, tamaño_destino-1) - 1;
                             valminent = - cast(int64_t)pow(2, tamaño_destino-1);
                        }

                        if(  (to!int64_t(origen.dato) > valmaxent)
                          || (to!int64_t(origen.dato) < valminent))
                        {
                            aborta("Has desbordado el tipo de dato. El valor "
                            ~ "máximo del tipo destino es '+"
                            ~ to!dstring(valmaxent) ~ "', y el valor mínimo es '-("
                            ~ to!dstring(valmaxent) ~ "+1)'");
                        }
                        else // el valor es menor que el valor máximo para el tipo
                        {
                            if((tamaño_destino > 1) && (tamaño_destino <= 16))
                            {
                                int16_t res = to!int16_t(origen.dato);
                                resultado.dato = to!dstring(res);
                            }
                            else if((tamaño_destino > 1) && (tamaño_destino <= 32))
                            {
                                int32_t res = to!int32_t(origen.dato);
                                resultado.dato = to!dstring(res);
                            }
                            else if((tamaño_destino > 1) && (tamaño_destino <= 64))
                            {
                                int64_t res = to!int64_t(origen.dato);
                                resultado.dato = to!dstring(res);
                            }
                        }
                    }
                    // El tamaño no está en el rango
                    else
                    {
                        aborta("el rango de tamaño del tipo es 2-64 bits, y has"
                        ~ " pedido " ~ destino.tipo[1..$] ~ " bits");
                    }
                    break;

                case 'r':
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);

                    // en los reales cuando se desborda se para en +/-infinito.
                    // El problema principal, no evitable, es la pérdida de
                    // precisión con números muy positivos o muy negativos.
                    // La máxima precisión se encuentra en torno al cero.

                    if((tamaño_destino > 0) && (tamaño_destino <= 32))
                    {
                        float res = to!float(origen.dato);
                        resultado.dato = to!dstring(res);
                    }
                    else if((tamaño_destino > 0) && (tamaño_destino <= 64))
                    {
                        double res = to!double(origen.dato);
                        resultado.dato = to!dstring(res);
                    }
                    else
                    {
                        aborta("el tamaño del tipo máximo es 64 bits, y has"
                        ~ " pedido " ~ destino.tipo[1..$] ~ "bits");
                    }
                    
                    break;

                default:
                    aborta("tipo desconocido");
                    break;
            }

            break;

        case 'e':
            tamaño_origen = to!uint32_t(t.tipo[1..$]);

            switch(destino.tipo[0])
            {
                case 'n': // convertimos de entero a natural
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);
                    
                    if(to!int64_t(origen.dato) < 0)
                    {
                        aborta("Intentas convertir en 'natural' un entero negativo");
                    }

                    // Hay espacio suficiente
                    if(tamaño_destino > tamaño_origen)
                    {
                        if((tamaño_destino > 0) && (tamaño_destino <= 16))
                        {
                            uint16_t res = to!uint16_t(origen.dato);
                            resultado.dato = to!dstring(res);
                        }
                        else if((tamaño_destino > 0) && (tamaño_destino <= 32))
                        {
                            uint32_t res = to!uint32_t(origen.dato);
                            resultado.dato = to!dstring(res);
                        }
                        else if((tamaño_destino > 0) && (tamaño_destino <= 64))
                        {
                            uint64_t res = to!uint64_t(origen.dato);
                            resultado.dato = to!dstring(res);
                        }
                        else
                        {
                            aborta("el tamaño del tipo máximo es 64 bits, y has"
                            ~ " pedido " ~ destino.tipo[1..$] ~ " bits");
                        }
                    }
                    // Puede que ocurran desbordes
                    else // (tamaño_destino <= tamaño_origen)
                    {
                        uint64_t valmaxnat;

                        if(tamaño_destino < 1)
                        {
                            aborta("El tamaño del tipo de destino es erróneo");
                        }
                        else if(tamaño_destino == 64)
                        {
                            valmaxnat = uint.max;
                        }
                        else if(tamaño_destino < 64)
                        {
                             valmaxnat = pow(2, tamaño_destino) - 1;
                        }

                        if(to!uint64_t(origen.dato) > valmaxnat)
                        {
                            aborta("Has desbordado el tipo de dato. El valor "
                            ~ "máximo del tipo destino es " ~
                            to!dstring(valmaxnat));
                        }
                        else // el valor es menor que el valor máximo para el tipo
                        {
                            if((tamaño_destino > 0) && (tamaño_destino <= 16))
                            {
                                uint16_t res = to!uint16_t(origen.dato);
                                resultado.dato = to!dstring(res);
                            }
                            else if((tamaño_destino > 0) && (tamaño_destino <= 32))
                            {
                                uint32_t res = to!uint32_t(origen.dato);
                                resultado.dato = to!dstring(res);
                            }
                            else if((tamaño_destino > 0) && (tamaño_destino <= 64))
                            {
                                uint64_t res = to!uint64_t(origen.dato);
                                resultado.dato = to!dstring(res);
                            }
                            else
                            {
                                aborta("el tamaño del tipo máximo es 64 bits, y has"
                                ~ " pedido " ~ destino.tipo[1..$] ~ " bits");
                            }
                        }
                    }

                    break;

                case 'e':
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);

                    // Disponemos de espacio
                    if(tamaño_destino >= tamaño_origen)
                    {
                        if((tamaño_destino > 1) && (tamaño_destino <= 16))
                        {
                            int16_t res = to!int16_t(origen.dato);
                            resultado.dato = to!dstring(res);
                        }
                        else if((tamaño_destino > 1) && (tamaño_destino <= 32))
                        {
                            int32_t res = to!int32_t(origen.dato);
                            resultado.dato = to!dstring(res);
                        }
                        else if((tamaño_destino > 1) && (tamaño_destino <= 64))
                        {
                            int64_t res = to!int64_t(origen.dato);
                            resultado.dato = to!dstring(res);
                        }
                        else
                        {
                            aborta("el tamaño del tipo máximo es 64 bits, y has"
                            ~ " pedido " ~ destino.tipo[1..$] ~ "bits");
                        }
                        
                    }
                    // Pueden ocurrir desbordes, tanto hacia los números
                    // positivos como hacia los negativos
                    else if(tamaño_destino > 1)
                    {
                        int64_t valmaxent;
                        int64_t valminent;
                        
                        if(tamaño_destino == 64)
                        {
                            valmaxent = int.max;
                            valminent = int.min;
                        }
                        else if((tamaño_destino < 64) && (tamaño_destino > 1))
                        {
                             valmaxent = pow(2, tamaño_destino-1) - 1;
                             valminent = cast(int64_t)(-1) * cast(int64_t)(pow(2, tamaño_destino-1));
                        }
                        else
                        {
                            aborta("El tamaño del tipo de destino se sale del rango");
                        }

                        if( to!int64_t(origen.dato) > valmaxent )
                        {
                            aborta("Has desbordado el tipo de dato. El valor "
                            ~ "máximo del tipo destino es '+"
                            ~ to!dstring(valmaxent) ~ "'");
                        }
                        else if( to!int64_t(origen.dato) < valminent )
                        {
                            aborta("Has desbordado el tipo de dato. El valor "
                            ~ "mínimo es '-(" ~ to!dstring(valmaxent) ~ "+1)'");
                        }
                        // el valor es menor que el valor máximo para el tipo
                        // y mayor que el valor mínimo del tipo
                        else
                        {
                            if((tamaño_destino > 1) && (tamaño_destino <= 16))
                            {
                                int16_t res = to!int16_t(origen.dato);
                                resultado.dato = to!dstring(res);
                            }
                            else if((tamaño_destino > 0) && (tamaño_destino <= 32))
                            {
                                int32_t res = to!int32_t(origen.dato);
                                resultado.dato = to!dstring(res);
                            }
                            else if((tamaño_destino > 0) && (tamaño_destino <= 64))
                            {
                                int64_t res = to!int64_t(origen.dato);
                                resultado.dato = to!dstring(res);
                            }
                        }
                    }
                    // El tamaño no está en el rango
                    else
                    {
                        aborta("el rango de tamaño del tipo es 2-64 bits, y has"
                        ~ " pedido " ~ destino.tipo[1..$] ~ " bits");
                    }
                    break;

                case 'r':
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);

                    // en los reales cuando se desborda se para en +/-infinito.
                    // El problema principal, no evitable, es la pérdida de
                    // precisión con números muy positivos o muy negativos.
                    // La máxima precisión se encuentra en torno al cero.

                    if((tamaño_destino > 1) && (tamaño_destino <= 32))
                    {
                        float res = to!float(origen.dato);
                        resultado.dato = to!dstring(res);
                    }
                    else if((tamaño_destino > 1) && (tamaño_destino <= 64))
                    {
                        double res = to!double(origen.dato);
                        resultado.dato = to!dstring(res);
                    }
                    else
                    {
                        aborta("el tamaño del tipo máximo es 64 bits, y has"
                        ~ " pedido " ~ destino.tipo[1..$] ~ "bits");
                    }

                    break;

                default:
                    aborta("tipo desconocido");
                    break;
            }
            
            break;

        case 'r':
            tamaño_origen = to!uint32_t(t.tipo[1..$]);

            switch(destino.tipo[0])
            {
                case 'n':
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);

                    uint64_t valmaxnat;

                    if(tamaño_destino < 1)
                    {
                        aborta("El tamaño del tipo de destino es erróneo");
                    }
                    else if(tamaño_destino == 64)
                    {
                        valmaxnat = uint.max;
                    }
                    else if(tamaño_destino < 64)
                    {
                            valmaxnat = cast(int64_t)pow(2, tamaño_destino) - 1;
                    }
                    else
                    {
                        aborta("El tipo se sale de rango");
                    }

                    if(to!double(origen.dato) > to!double(valmaxnat))
                    {
                        aborta("El 'real' se sale del rango del 'natural'");
                    }
                    else
                    {
                        uint64_t res = to!uint64_t(to!double(origen.dato));
                        resultado.dato = to!dstring(res);
                    }
                    
                    break;

                case 'e':
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);
                    
                    int64_t valmaxent;
                    int64_t valminent;

                    if(tamaño_destino < 2)
                    {
                        aborta("El tamaño del tipo de destino es erróneo");
                    }
                    else if(tamaño_destino == 64)
                    {
                        valmaxent = int.max;
                        valminent = int.min;
                    }
                    else if(tamaño_destino < 64)
                    {
                            valmaxent = pow(2, tamaño_destino-1) - 1;
                            valminent = - cast(int64_t)pow(2, tamaño_destino-1);
                    }
                    else
                    {
                        aborta("El tipo se sale de rango");
                    }

                    if( (to!double(origen.dato) > to!double(valmaxent))
                     || (to!double(origen.dato) < to!double(valminent))
                    )
                    {
                        writeln(origen.dato);
                        writeln(valmaxent);
                        writeln(valminent);
                        aborta("El 'real' se sale del rango del 'entero'");
                    }
                    else
                    {
                        int64_t res = to!int64_t(to!double(origen.dato));
                        resultado.dato = to!dstring(res);
                    }
                    
                    break;

                case 'r':
                    tamaño_destino = to!uint32_t(destino.tipo[1..$]);
                    
                    double res = to!double(origen.dato);
                    resultado.dato = to!dstring(res);

                    break;

                default:
                    aborta("tipo desconocido");
                    break;
            }
            
            break;

        default:
            aborta("tipo desconocido");
            break;
    }

    info("op: " ~ op.dato ~ " ");
    info(t.tipo ~ " " ~ origen.dato);
    info(" => " ~ (cast(Tipo)(op.ramas[2])).tipo);

    if(resultado is null)
    {
        infoln(" [null]");
        return null;
    }
    else
    {
        infoln(" [" ~ resultado.tipo ~ ":" ~ resultado.dato ~ "]");

        return resultado;
    }
}

Etiqueta op_slt(Operación op)
{
    if(op.dato != "slt")
    {
        aborta("Esperaba que el código de la operación fuera 'slt'");
        return null;
    }

    // Salto incondicional
    // slt :<etiqueta>
    if(op.ramas.length == 1)
    {
        Etiqueta etiqueta = cast(Etiqueta)(op.ramas[0]);

        if(tid.lee_id(etiqueta.dato).nombre)
        {
            dstring nombre = tid.lee_id(etiqueta.dato).nombre;

            Literal l = cast(Literal)(tid.lee_id(etiqueta.dato).valor);
            int contador = to!int(l.dato);
            etiqueta.línea = contador;

            infoln("op: slt " ~ nombre ~ to!dstring(contador));

            return etiqueta;
        }
        else
        {
            aborta("La etiqueta no existe");
        }
    }
    // Salto condicional
    // slt n1 (<id>|<literal>) :<etiqueta>
    else if(op.ramas.length == 3)
    {
        Tipo t = cast(Tipo)(op.ramas[0]);
        bool condición = false;

        if(t is null)
        {
            aborta("Tipo 'null'.\nslt [n1 (<id>|<literal>)] :<etiqueta>");
            return null;
        }
        else if(t.tipo != "n1")
        {
            aborta("Tipo incorrecto. Esperaba 'n1'.\nslt [n1 (<id>|<literal>)] :<etiqueta>");
            return null;
        }
        else
        {
            condición = (t.tipo == "1");
        }
        
        Literal lit = lee_argumento(op.ramas[1]);
        
        if(condición)
        {
            // Se cumple la condición
            Etiqueta etiqueta = cast(Etiqueta)(op.ramas[2]);

            if(tid.lee_id(etiqueta.dato).nombre)
            {
                dstring nombre = tid.lee_id(etiqueta.dato).nombre;

                Literal l = cast(Literal)(tid.lee_id(etiqueta.dato).valor);
                int contador = to!int(l.dato);
                etiqueta.línea = contador;

                infoln("op: slt [n1:1] " ~ nombre ~ "["
                     ~ to!dstring(contador) ~ "]");

                return etiqueta;
            }
            else
            {
                aborta("La etiqueta no existe");
            }
        }
        else
        {
            // No se cumple la condición
            return null;
        }
    }

    aborta("slt [n1 (<id>|<literal>)] :<etiqueta>");
    return null;
}

Literal op_phi(Operación op)
{
    dstring etiqueta;
    Tipo t;
    Literal lit;

    if(tid.última_etiqueta().length > 0)
    {
        etiqueta = tid.última_etiqueta();
        charlatánln("ETIQUETA: " ~ etiqueta);
    }
    else
    {
        aborta("PHI: No ha llegado a declararse ninguna etiqueta");
    }

    if(op.dato != "phi")
    {
        aborta("Esperaba que el código de la operación fuera 'phi'");
        return null;
    }

    t = cast(Tipo)(op.ramas[0]);
    if(t is null)
    {
        aborta("Esperaba Tipo.\nphi <tipo> '[' <id>|<literal>, :<etiqueta> ']',... ");
    }

    if((op.ramas.length > 2) && ((op.ramas.length % 2) == 1))
    {
        // phi tiene un número par de argumentos
        for(int i = 2; i < (op.ramas.length); i+2)
        {
            Nodo n = op.ramas[i];
            if(n.categoría != Categoría.ETIQUETA)
            {
                aborta("Esperaba una etiqueta");
            }
            else
            {
                auto e = cast(Etiqueta)n;
                if(e.dato == etiqueta)
                {
                    lit = cast(Literal)op.ramas[i - 1];

                    lit.tipo = t.tipo;

                    return lit;
                }

                aborta("Esperaba Etiqueta.\nphi <tipo> '[' <id>|<literal>, :<etiqueta> ']',... ");
                return null;
            }
        }

        aborta("La última etiqueta no se ha declarado en 'phi'");
        return null;
    }
    
    aborta("Esperaba que 'phi' tuviera un número impar de argumentos, y al menos 3");
    return null;
}