module sintaxis;

import std.stdio;

import apoyo;
import arbol;

private uint cursor = 0;
private lexema[] símbolos;

public Nodo analiza(lexema[] lexemas)
{
    símbolos = lexemas;
    return objeto();
}


//OBJETO := [objeto NOMBRE;] [DECL_GLOB | DEF_GLOB]*
private Objeto objeto()
{
    uint c = cursor;
    bool línea = false;

    Objeto o = new Objeto();

    if(auto r = reservada("objeto"))
    {
        o.línea = r.línea;
        línea = true;

        if(auto n = nombre())
        {
            o.nombre = n.dato;
        }
        if(!notación(";"))
        {
            cursor = c;
            return null;
        }
    }

    while(true)
    {
        if(auto d = declaración_global())
        {
            if(!línea)
            {
                o.línea = d.línea;
            }

            o.ramas ~= d;
            continue;
        }
        else if(auto d = definición_global())
        {
            if(!línea)
            {
                o.línea = d.línea;
            }

            o.ramas ~= d;
            continue;
        }

        break;
    }

    return o;
}


//DECL_GLOB := ( EXT_ID | DEF_FUNC )
private Nodo declaración_global()
{
    uint c = cursor;
    
    if(auto r = declara_función())
    {
        if(notación(";"))
        {
            return r;
        }
    }
    else if(auto r = declara_identificador_externo())
    {
        if(notación(";"))
        {
            return r;
        }
    }

    cursor = c;
    return null;
}


//DEF_GLOB := ( DEF_FUNC | DEF_ID )
private Nodo definición_global()
{
    uint c = cursor;

    if(auto r = define_función())
    {
        return r;
    }
    else if(auto r = define_identificador())
    {
        if(notación(";"))
        {
            return r;
        }
    }

    cursor = c;
    return null;
}


//DEF_FUNCIÓN := define TIPO ID_GLOBAL ( [TIPO]* ) BLOQUE
private DefineFunción define_función()
{
    uint c = cursor;

    if(auto n = reservada("define"))
    {

        auto df = new DefineFunción();
        df.línea = n.línea;

        if(Nodo r = tipo())
        {
            df.retorno = r.dato;
        }

        if(Nodo r = identificador())
        {
            df.nombre = r.dato;
        }
        else
        {
            return null;
        }

        if(!(notación("(")))
        {
            return null;
        }

        if(Nodo a = argumentos())
        {
            df.ramas ~= a;
        }

        if(!(notación(")")))
        {
            return null;
        }

        if(Nodo b = bloque())
        {
            df.ramas ~= b;
        }
        else
        {
            return null;
        }
        
        return df;
    }
    else
    {
        cursor = c;
        return null;
    }
}


//DECL_FUNCIÓN := RESERV_DECL TIPO ID_GLOBAL NOTA_ABRE_PAREN [TIPO]* NOTA_CIERRA_PAREN
private DeclaraFunción declara_función()
{
    uint c = cursor;

    if(auto n = reservada("declara"))
    {
        auto df = new DeclaraFunción();
        df.línea = n.línea;

        if(Nodo r = tipo())
        {
            df.retorno = r.dato;
        }

        if(Nodo r = identificador())
        {
            df.nombre = r.dato;
        }
        else
        {
            return null;
        }

        if(!(notación("(")))
        {
            return null;
        }

        if(Nodo a = argumentos)
        {
            df.ramas ~= a;
        }

        if(!(notación(")")))
        {
            return null;
        }

        return df;
    }

    cursor = c;
    return null;
}


//ARGUMENTOS := [ARGUMENTO [ NOTA_COMA ARGUMENTO]* ]
private Argumentos argumentos()
{
    uint c = cursor;

    auto a = new Argumentos();
    if(auto arg = argumento())
    {
        a.línea = arg.línea;
        a.ramas ~= arg;

        while(notación(","))
        {
            arg = argumento();

            if(arg)
            {
                a.ramas ~= arg;
            }
            else
            {
                break;
            }
        }

        return a;
    }
    
    cursor = c;
    return null;
}


//ARGUMENTO := TIPO IDENTIFICADOR
private Argumento argumento()
{
    uint c = cursor;

    auto a = new Argumento();
    if(auto t = tipo())
    {
        if(auto i = identificador())
        {
            a.tipo = t.dato;
            a.nombre = i.dato;
            a.línea = t.línea;

            return a;
        }
    }

    cursor = c;
    return null;
}


//BLOQUE := NOTA_ABRE_LLAVE [AFIRMACIÓN]* NOTA_CIERRA_LLAVE
private Nodo bloque()
{
    uint c = cursor;

    if(auto n = notación("{"))
    {
        auto b = new Bloque();
        b.línea = n.línea;

        Nodo r;
        do {
            r = afirmación();
            if(r)
            {
                b.ramas ~= r;
            }
        } while(r);

        if(notación("}"))
        {
            return b;
        }
    }
    
    cursor = c;
    return null;
}


//AFIRMACIÓN := (ASIGNACIÓN | DEF_ID | OP) ;
private Nodo afirmación()
{
    uint c = cursor;
    
    if(auto r = asignación())
    {
        if(notación(";"))
        {
            return r;
        }
    }
    else if(auto r = operación())
    {
        if(notación(";"))
        {
            return r;
        }
    }
    else if(auto r = define_identificador())
    {
        if(notación(";"))
        {
            return r;
        }
    }

    cursor = c;
    return null;
}


//EXT_ID := externo TIPO ID
private IdentificadorExterno declara_identificador_externo()
{
    uint c = cursor;
    
    auto e = new IdentificadorExterno();
    if(auto n = reservada("externo"))
    {
        e.ámbito = "externo";
        e.línea = n.línea;
    }

    if(auto n = tipo())
    {
        e.tipo = n.dato;
    }
    else
    {
        cursor = c;
        return null;
    }

    if(auto id = identificador())
    {
        e.nombre = id.dato;
    }
    else
    {
        cursor = c;
        return null;
    }

    return e;
}


//DEF_ID := [global | local] TIPO ID = LITERAL
private DefineIdentificador define_identificador()
{
    uint c = cursor;
    bool línea = false;
    
    auto i = new DefineIdentificador();
    if(auto n = reservada("global"))
    {
        i.ámbito = "global";
        i.línea = n.línea;
        línea = true;
    }
    else if(auto n = reservada("local"))
    {
        i.ámbito = "local";
        i.línea = n.línea;
        línea = true;
    }

    if(auto n = tipo())
    {
        i.tipo = n.dato;
        if(!línea)
        {
            i.línea = n.línea;
        }
    }
    else
    {
        cursor = c;
        return null;
    }

    if(auto id = identificador())
    {
        i.nombre = id.dato;
    }
    else
    {
        cursor = c;
        return null;
    }

    if(!notación("="))
    {
        cursor = c;
        return null;
    }

    if(auto l = literal())
    {
        i.ramas ~= l;
    }
    else
    {
        cursor = c;
        return null;
    }

    return i;
}


//ASIGNACIÓN := ID COD_ASIGN OPERACIÓN
private Asignación asignación()
{
    uint c = cursor;

    auto a = new Asignación();
    Nodo r1, r2;

    if(Nodo r = identificador())
    {
        r1 = r;
    }
    else
    {
        cursor = c;
        return null;
    }

    if(!notación("="))
    {
        cursor = c;
        return null;
    }

    if(Nodo r = operación())
    {
        r2 = r;
        a.línea = r1.línea;
        a.ramas ~= r1;
        a.ramas ~= r2;
        return a;
    }

    cursor = c;
    return null;
}


//OPERACIÓN -- COD_OP  [ (ID | LITERAL) [, (ID | LITERAL) ]* ]
private Operación operación()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.OPERACIÓN)
        {
            Operación o = new Operación();
            o.dato = símbolos[cursor].símbolo;
            o.línea = símbolos[cursor].línea;

            cursor++;

            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Literal l = literal())
            {
                o.ramas ~= l;
            }
            else
            {
                return o;
            }

            while(true)
            {
                uint c1 = cursor;

                if(!notación(","))
                {
                    cursor = c1;
                    break;
                }

                if(Identificador i = identificador())
                {
                    o.ramas ~= i;
                    continue;
                }
                else cursor = c1;

                if(Literal l = literal())
                {
                    o.ramas ~= l;
                    continue;
                }
                else cursor = c1;

                break;
            }

            return o;
        }
    }

    cursor = c;
    return null;
}


//IDENTIFICADOR -- (REGISTRO | IDLOCAL | IDGLOBAL)
private Identificador identificador()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.IDENTIFICADOR)
        {
            Identificador i = new Identificador();
            i.dato = símbolos[cursor].símbolo;
            i.línea = símbolos[cursor].línea;
            
            cursor++;
            return i;
        }
    }

    cursor = c;
    return null;
}


//LITERAL -- TIPO NÚMERO
private Literal literal()
{
    uint c = cursor;

    if(Nodo t = tipo())
    {
        if(Nodo n = número())
        {
            auto l = new Literal();
            l.tipo = t.dato;
            l.dato = n.dato;
            l.línea = t.línea;

            return l;
        }
    }
    cursor = c;
    return null;
}


//NÚMERO -- lexema_e.NÚMERO, dstring Nº, uint64_t línea
private Nodo número()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.NÚMERO)
        {
            Nodo n = new Nodo();
            n.categoría = Categoría.NÚMERO;
            n.dato = símbolos[cursor].símbolo;
            n.línea = símbolos[cursor].línea;

            cursor++;
            return n;
        }
    }

    cursor = c;
    return null;
}


//TIPO -- lexema_e.TIPO, dstring n|e|r+Nº, uint64_t línea
private Nodo tipo()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.TIPO)
        {
            Nodo n = new Nodo();
            n.categoría = Categoría.TIPO;
            n.dato = símbolos[cursor].símbolo;
            n.línea = símbolos[cursor].línea;
            
            cursor++;
            return n;
        }
    }

    cursor = c;
    return null;
}


private Nodo nombre()
{
    if(cursor >= símbolos.length)
    {
        if(INFO)
        {
            write("ERROR: he llegado al final del archivo y esperaba nombre");
            writeln("'");
        }
        
        return null;
    }

    if(símbolos[cursor].categoría == lexema_e.NOMBRE)
    {
        if(INFO)
        {
            writeln("not["d ~ símbolos[cursor].símbolo ~ "]"d);
        }

        Nodo n = new Nodo();
        n.dato = símbolos[cursor].símbolo;
        n.línea = símbolos[cursor].línea;

        cursor++;
        return n;
    }

    return null;
}


private Nodo reservada(dstring txt)
{
    if(cursor >= símbolos.length)
    {
        if(INFO)
        {
            write("ERROR: he llegado al final del archivo y esperaba '");
            write(txt);
            writeln("'");
        }
        
        return null;
    }

    if((símbolos[cursor].categoría == lexema_e.RESERVADA) && (símbolos[cursor].símbolo == txt))
    {
        if(INFO)
        {
            writeln("not["d ~ txt ~ "]"d);
        }

        Nodo n = new Nodo();
        n.línea = símbolos[cursor].línea;

        cursor++;
        return n;
    }

    return null;
}


private Nodo notación(dstring c)
{
    if(cursor >= símbolos.length)
    {
        if(INFO)
        {
            write("ERROR: he llegado al final del archivo y esperaba '");
            write(c);
            writeln("'");
        }
        
        return null;
    }

    if((símbolos[cursor].categoría == lexema_e.NOTACIÓN) && (símbolos[cursor].símbolo == c))
    {
        if(INFO)
        {
            writeln("not["d ~ c ~ "]"d);
        }

        Nodo n = new Nodo();
        n.línea = símbolos[cursor].línea;

        cursor++;
        return n;
    }

    return null;
}
