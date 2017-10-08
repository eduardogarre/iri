module semantico;

import apoyo;
import arbol;
import std.conv;
import std.stdint;
import std.stdio;

// Implemento la tabla de identificadores como un diccionario:
// Para acceder a cada una de las entradas, se usa el nombre del identificador.

TablaIdentificadores tid;

bool analiza(Nodo n)
{
    imprime_árbol(n);

	infoln();

    paso1_identificadores_globales(n);

    infoln();

    Bloque bloque = paso2_prepara_inicio();

    paso3_ejecuta(bloque);

    return true;
}

void paso1_identificadores_globales(Nodo n)
{
    infoln("Recorre espacio de nombres 'global'.");

    paso1_recorre_nodo(n);
}

Bloque paso2_prepara_inicio()
{
    infoln("Ejecuta '@inicio()'.");
    
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

    // Obtén el Nodo de la definición de @inicio()
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
    tid.define_identificador("pi", literal, literal);

    // Comprueba las variables guardadas en las tablas de identificadores
    infoln("Comprobando que %pi existe...");
    recorre_nodo(tid.lee_id("%pi").definición);

    infoln("Comprobando que %lolazo existe...");
    recorre_nodo(tid.lee_id("%lolazo").definición);


    //paso 2.2: obtén el bloque de @inicio(), para poder ejecutarlo.
    Bloque bloque = paso2_2_obtén_bloque(def_inicio);

    if(bloque is null)
    {
        aborta("No puedo ejecutar el bloque de @inicio");
    }

    return bloque;
}

void paso3_ejecuta(Bloque bloque)
{
    Nodo resultado;
    //recorre las ramas del bloque de @inicio()
    for(int i = 0; i<bloque.ramas.length; i++)
    {
        resultado = paso3_recorre_nodo(bloque.ramas[i]);
    }
}

Nodo paso3_recorre_nodo(Nodo n)
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
                info(to!dstring(l.categoría));
                info(" [id:");
                info(l.dato);
                info("] [línea:");
                info(to!dstring(l.línea));
                infoln("]");
                return null;
                //break;

            case Categoría.OPERACIÓN:
                auto o = cast(Operación)n;
                return ejecuta_operación(o);
                //break;

            case Categoría.ASIGNACIÓN:
                auto a = cast(Asignación)n;

                auto id = cast(Identificador)a.ramas[0];

                auto lit = cast(Literal)paso3_recorre_nodo(a.ramas[1]);

                tid.define_identificador(id.dato, a, lit);

                return null;
                //break;

            case Categoría.DEFINE_IDENTIFICADOR_LOCAL:
                auto did = cast(DefineIdentificadorLocal)n;
                info(to!dstring(did.categoría));
                info(" [ámbito:");
                info(did.ámbito);
                info("] [tipo:");
                info(did.tipo);
                info("] [nombre:");
                info(did.nombre);
                info("] [línea:");
                info(to!dstring(did.línea));
                infoln("]");
                return null;
                //break;

            case Categoría.DEFINE_IDENTIFICADOR_GLOBAL:
                auto did = cast(DefineIdentificadorGlobal)n;
                info(to!dstring(did.categoría));
                info(" [ámbito:");
                info(did.ámbito);
                info("] [tipo:");
                info(did.tipo);
                info("] [nombre:");
                info(did.nombre);
                info("] [línea:");
                info(to!dstring(did.línea));
                infoln("]");
                return null;
                //break;

            case Categoría.DECLARA_IDENTIFICADOR_GLOBAL:
                auto idex = cast(DeclaraIdentificadorGlobal)n;
                info(to!dstring(idex.categoría));
                info(" [ámbito:");
                info(idex.ámbito);
                info("] [tipo:");
                info(idex.tipo);
                info("] [nombre:");
                info(idex.nombre);
                info("] [línea:");
                info(to!dstring(idex.línea));
                infoln("]");
                return null;
                //break;

            case Categoría.BLOQUE:
                auto b = cast(Bloque)n;
                info(to!dstring(b.categoría));
                info(" [línea:");
                info(to!dstring(b.línea));
                infoln("]");
                return null;
                //break;

            case Categoría.ARGUMENTOS:
                auto a = cast(Argumentos)n;
                info(to!dstring(a.categoría));
                info(" [línea:");
                info(to!dstring(a.línea));
                infoln("]");
                return null;
                //break;

            case Categoría.ARGUMENTO:
                auto a = cast(Argumento)n;
                info(to!dstring(a.categoría));
                info(" [tipo:");
                info(a.tipo);
                info("] [nombre:");
                info(a.nombre);
                info("] [línea:");
                info(to!dstring(a.línea));
                infoln("]");
                return null;
                //break;

            case Categoría.DEFINE_FUNCIÓN:
                auto df = cast(DefineFunción)n;
                info(to!dstring(df.categoría));
                info(" [ret:");
                info(df.retorno);
                info("] [nombre:");
                info(df.nombre);
                info("] [línea:");
                info(to!dstring(df.línea));
                infoln("]");
                return null;
                //break;

            case Categoría.DECLARA_FUNCIÓN:
                auto df = cast(DeclaraFunción)n;
                info(to!dstring(df.categoría));
                info(" [ret:");
                info(df.retorno);
                info("] [nombre:");
                info(df.nombre);
                info("] [línea:");
                info(to!dstring(df.línea));
                infoln("]");
                return null;
                //break;

            case Categoría.MÓDULO:
                auto obj = cast(Módulo)n;
                info(to!dstring(obj.categoría));
                info(" [nombre:");
                info(obj.nombre);
                info("] [línea:");
                info(to!dstring(obj.línea));
                infoln("]");
                return null;
                //break;

            default:
                return null;
                //break;
        }
    }

    return null;
}

void paso2_1_declara_argumentos(Nodo n)
{
    infoln("Declara los argumentos de @inicio().");
    
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
                return EntradaTablaIdentificadores(null, false, null, false, null, null);
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

    bool define_identificador(dstring identificador, Nodo definición, Literal valor)
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
        eid.valor = valor;

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
            info("   ");
        }
        info("[hijos:");
        info(to!dstring(n.ramas.length));
        info("] ");
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
            info(to!dstring(l.categoría));
            info(" [tipo:");
            info(l.tipo);
            info("] [dato:");
            info(l.dato);
            info("] [línea:");
            info(to!dstring(l.línea));
            infoln("]");
            break;

        case Categoría.IDENTIFICADOR:
            auto l = cast(Identificador)n;
            info(to!dstring(l.categoría));
            info(" [id:");
            info(l.dato);
            info("] [línea:");
            info(to!dstring(l.línea));
            infoln("]");
            break;

        case Categoría.LLAMA_FUNCIÓN:
            auto l = cast(LlamaFunción)n;
            info(to!dstring(l.categoría));
            info(" [id:");
            info(l.nombre);
            info(" [devuelve:");
            info(l.tipo);
            info("] [línea:");
            info(to!dstring(l.línea));
            infoln("]");
            break;

        case Categoría.OPERACIÓN:
            auto o = cast(Operación)n;
            info(to!dstring(o.categoría));
            info(" [op:");
            info(o.dato);
            info("] [línea:");
            info(to!dstring(o.línea));
            infoln("]");
            break;

        case Categoría.ASIGNACIÓN:
            auto a = cast(Asignación)n;
            info(to!dstring(a.categoría));
            info(" [línea:");
            info(to!dstring(a.línea));
            infoln("]");
            break;

        case Categoría.DEFINE_IDENTIFICADOR_LOCAL:
            auto did = cast(DefineIdentificadorLocal)n;
            info(to!dstring(did.categoría));
            info(" [ámbito:");
            info(did.ámbito);
            info("] [tipo:");
            info(did.tipo);
            info("] [nombre:");
            info(did.nombre);
            info("] [línea:");
            info(to!dstring(did.línea));
            infoln("]");
            break;

        case Categoría.DEFINE_IDENTIFICADOR_GLOBAL:
            auto did = cast(DefineIdentificadorGlobal)n;
            info(to!dstring(did.categoría));
            info(" [ámbito:");
            info(did.ámbito);
            info("] [tipo:");
            info(did.tipo);
            info("] [nombre:");
            info(did.nombre);
            info("] [línea:");
            info(to!dstring(did.línea));
            infoln("]");
            break;

        case Categoría.DECLARA_IDENTIFICADOR_GLOBAL:
            auto idex = cast(DeclaraIdentificadorGlobal)n;
            info(to!dstring(idex.categoría));
            info(" [ámbito:");
            info(idex.ámbito);
            info("] [tipo:");
            info(idex.tipo);
            info("] [nombre:");
            info(idex.nombre);
            info("] [línea:");
            info(to!dstring(idex.línea));
            infoln("]");
            break;

        case Categoría.BLOQUE:
            auto b = cast(Bloque)n;
            info(to!dstring(b.categoría));
            info(" [línea:");
            info(to!dstring(b.línea));
            infoln("]");
            break;

        case Categoría.ARGUMENTOS:
            auto a = cast(Argumentos)n;
            info(to!dstring(a.categoría));
            info(" [línea:");
            info(to!dstring(a.línea));
            infoln("]");
            break;

        case Categoría.ARGUMENTO:
            auto a = cast(Argumento)n;
            info(to!dstring(a.categoría));
            info(" [tipo:");
            info(a.tipo);
            info("] [nombre:");
            info(a.nombre);
            info("] [línea:");
            info(to!dstring(a.línea));
            infoln("]");
            break;

        case Categoría.DEFINE_FUNCIÓN:
            auto df = cast(DefineFunción)n;
            info(to!dstring(df.categoría));
            info(" [ret:");
            info(df.retorno);
            info("] [nombre:");
            info(df.nombre);
            info("] [línea:");
            info(to!dstring(df.línea));
            infoln("]");
            break;

        case Categoría.DECLARA_FUNCIÓN:
            auto df = cast(DeclaraFunción)n;
            info(to!dstring(df.categoría));
            info(" [ret:");
            info(df.retorno);
            info("] [nombre:");
            info(df.nombre);
            info("] [línea:");
            info(to!dstring(df.línea));
            infoln("]");
            break;

        case Categoría.MÓDULO:
            auto obj = cast(Módulo)n;
            info(to!dstring(obj.categoría));
            info(" [nombre:");
            info(obj.nombre);
            info("] [línea:");
            info(to!dstring(obj.línea));
            infoln("]");
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
                infoln("define " ~ tid.lee_id(did.nombre).nombre);
            }

            break;

        case Categoría.DECLARA_IDENTIFICADOR_GLOBAL:
            auto idex = cast(DeclaraIdentificadorGlobal)n;

            if(tid.declara_identificador(idex.nombre, idex))
            {
                infoln("declara " ~ tid.lee_id(idex.nombre).nombre);
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
                infoln("define " ~ tid.lee_id(df.nombre).nombre);
            }

            break;

        case Categoría.DECLARA_FUNCIÓN:
            auto df = cast(DeclaraFunción)n;

            if(tid.declara_identificador(df.nombre, df))
            {
                infoln("declara " ~ tid.lee_id(df.nombre).nombre);
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
                infoln("declara " ~ tid.lee_id(a.nombre).nombre);
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
        Nodo l = (tid.lee_id(id.dato).valor);
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

        default:
            break;
    }

    return null;
}

Literal op_ret(Operación op)
{
    if(op.dato != "ret")
    {
        aborta("Esperaba que el código de la operación fuera 'ret'");
        return null;
    }

    if(op.ramas.length == 1)
    {
        // ret tiene argumento
        Literal lit = lee_argumento(op.ramas[0]);
        infoln("op: ret " ~ lit.tipo ~ " " ~ lit.dato ~ " [" ~ lit.dato ~ "]");
        return lit;
    }
    else if(op.ramas.length == 0)
    {
        // ret no tiene argumento
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

    if(op.ramas.length != 2)
    {
        aborta("Esperaba que la operación 'sum' tuviera 2 argumentos");
        return null;
    }

    Nodo n;
    Literal lit0, lit1;
    
    n = op.ramas[0];
    lit0 = lee_argumento(n);
    
    n = op.ramas[1];
    lit1 = lee_argumento(n);

    if(lit0.tipo != lit1.tipo)
    {
        aborta("Los tipos de la operación 'sum' debían ser iguales");
        return null;
    }

    switch(lit0.tipo[0])
    {
        case 'e': //entero
            for(int i = 1; i < lit0.tipo.length; i++)
            {
                if(!esdígito(lit0.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(lit0.tipo[1..$]);

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
            l.tipo = lit0.tipo;

            dstring txt;
            txt = "op: sum " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e0)
                  ~ ", " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'n': //natural
            for(int i = 1; i < lit0.tipo.length; i++)
            {
                if(!esdígito(lit0.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(lit0.tipo[1..$]);

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
            l.tipo = lit0.tipo;

            dstring txt;
            txt = "op: sum " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n0)
                  ~ ", " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'r': //real
            for(int i = 1; i < lit0.tipo.length; i++)
            {
                if(!esdígito(lit0.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(lit0.tipo[1..$]);

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
            l.tipo = lit0.tipo;

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

    if(op.ramas.length != 2)
    {
        aborta("Esperaba que la operación 'res' tuviera 2 argumentos");
        return null;
    }

    Nodo n;
    Literal lit0, lit1;
    
    n = op.ramas[0];
    lit0 = lee_argumento(n);
    
    n = op.ramas[1];
    lit1 = lee_argumento(n);

    if(lit0.tipo != lit1.tipo)
    {
        aborta("Los tipos de la operación 'res' debían ser iguales");
        return null;
    }

    switch(lit0.tipo[0])
    {
        case 'e': //entero
            for(int i = 1; i < lit0.tipo.length; i++)
            {
                if(!esdígito(lit0.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(lit0.tipo[1..$]);

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
            l.tipo = lit0.tipo;

            dstring txt;
            txt = "op: res " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e0)
                  ~ ", " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'n': //natural
            for(int i = 1; i < lit0.tipo.length; i++)
            {
                if(!esdígito(lit0.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(lit0.tipo[1..$]);

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
            l.tipo = lit0.tipo;

            dstring txt;
            txt = "op: res " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n0)
                  ~ ", " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'r': //real
            for(int i = 1; i < lit0.tipo.length; i++)
            {
                if(!esdígito(lit0.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(lit0.tipo[1..$]);

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
            l.tipo = lit0.tipo;

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

    if(op.ramas.length != 2)
    {
        aborta("Esperaba que la operación 'mul' tuviera 2 argumentos");
        return null;
    }

    Nodo n;
    Literal lit0, lit1;
    
    n = op.ramas[0];
    lit0 = lee_argumento(n);
    
    n = op.ramas[1];
    lit1 = lee_argumento(n);

    if(lit0.tipo != lit1.tipo)
    {
        aborta("Los tipos de la operación 'mul' debían ser iguales");
        return null;
    }

    switch(lit0.tipo[0])
    {
        case 'e': //entero
            for(int i = 1; i < lit0.tipo.length; i++)
            {
                if(!esdígito(lit0.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(lit0.tipo[1..$]);

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
            l.tipo = lit0.tipo;

            dstring txt;
            txt = "op: mul " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e0)
                  ~ ", " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'n': //natural
            for(int i = 1; i < lit0.tipo.length; i++)
            {
                if(!esdígito(lit0.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(lit0.tipo[1..$]);

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
            l.tipo = lit0.tipo;

            dstring txt;
            txt = "op: mul " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n0)
                  ~ ", " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'r': //real
            for(int i = 1; i < lit0.tipo.length; i++)
            {
                if(!esdígito(lit0.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(lit0.tipo[1..$]);

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
            l.tipo = lit0.tipo;

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

    if(op.ramas.length != 2)
    {
        aborta("Esperaba que la operación 'div' tuviera 2 argumentos");
        return null;
    }

    Nodo n;
    Literal lit0, lit1;
    
    n = op.ramas[0];
    lit0 = lee_argumento(n);
    
    n = op.ramas[1];
    lit1 = lee_argumento(n);

    if(lit0.tipo != lit1.tipo)
    {
        aborta("Los tipos de la operación 'div' debían ser iguales");
        return null;
    }

    switch(lit0.tipo[0])
    {
        case 'e': //entero
            for(int i = 1; i < lit0.tipo.length; i++)
            {
                if(!esdígito(lit0.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(lit0.tipo[1..$]);

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
            l.tipo = lit0.tipo;

            dstring txt;
            txt = "op: div " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e0)
                  ~ ", " ~ "e" ~ to!dstring(tamaño) ~ " " ~ to!dstring(e1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'n': //natural
            for(int i = 1; i < lit0.tipo.length; i++)
            {
                if(!esdígito(lit0.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(lit0.tipo[1..$]);

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
            l.tipo = lit0.tipo;

            dstring txt;
            txt = "op: div " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n0)
                  ~ ", " ~ "n" ~ to!dstring(tamaño) ~ " " ~ to!dstring(n1);

            txt ~= " [" ~ to!dstring(resultado) ~ "]";

            infoln(txt);

            return l;
            //break;

        case 'r': //real
            for(int i = 1; i < lit0.tipo.length; i++)
            {
                if(!esdígito(lit0.tipo[i]))
                {
                    aborta("Formato incorrecto del 'tipo'");
                    return null;
                }
            }

            uint32_t tamaño = to!uint32_t(lit0.tipo[1..$]);

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
            l.tipo = lit0.tipo;

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
    
    foreach(Nodo n; f.ramas)
    {
        Literal l = lee_argumento(n);
        info(l.tipo ~ " " ~ l.dato ~ " ");
    }

    infoln(")");

    return null;
}