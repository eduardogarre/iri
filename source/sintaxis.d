module sintaxis;

import std.stdio;

import apoyo;
import arbol;

private uint cursor = 0;
private lexema[] símbolos;

public Nodo analiza(lexema[] lexemas)
{
    símbolos = lexemas;
    return módulo();
}


//MÓDULO := [módulo NOMBRE;] [DECL_GLOB | DEF_GLOB]*
private Módulo módulo()
{
    uint c = cursor;
    bool línea = false;

    Módulo o = new Módulo();

    if(auto r = reservada("módulo"))
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

    if(!fda())
    {
        aborta("Esperaba llegar al final del archivo");
    }

    return o;
}


//DECL_GLOB := ( DECL_ID_GLOB | DECL_FUNC )
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
    else if(auto r = declara_identificador_global())
    {
        if(notación(";"))
        {
            return r;
        }
    }

    cursor = c;
    return null;
}


//DEF_GLOB := ( DEF_FUNC | DEF_ID_GLOB )
private Nodo definición_global()
{
    uint c = cursor;

    if(auto r = define_función())
    {
        return r;
    }
    else if(auto r = define_identificador_global())
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

        if(Tipo r = tipo())
        {
            df.retorno = r.tipo;
        }

        if(Identificador r = identificador())
        {
            df.nombre = r.nombre;
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

        if(Tipo r = tipo())
        {
            df.retorno = r.tipo;
        }

        if(Identificador r = identificador())
        {
            df.nombre = r.nombre;
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
            a.tipo = t.tipo;
            a.nombre = i.nombre;
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


//AFIRMACIÓN := (ASIGNACIÓN | DEF_ID_LOC | OP) ;
private Nodo afirmación()
{
    uint c = cursor;

    auto e = etiqueta();
    
    if(auto r = asignación())
    {
        if(e !is null)
        {
            r.etiqueta = e.dato;
        }
        
        if(notación(";"))
        {
            return r;
        }
    }
    else if(auto r = operación())
    {
        if(e !is null)
        {
            r.etiqueta = e.dato;
        }
        
        if(notación(";"))
        {
            return r;
        }
    }
    else if(auto r = define_identificador_local())
    {
        if(e !is null)
        {
            r.etiqueta = e.dato;
        }
        
        if(notación(";"))
        {
            return r;
        }
    }

    cursor = c;
    return null;
}


//DECL_ID_GLOB := ID = (externo | global) TIPO
private DeclaraIdentificadorGlobal declara_identificador_global()
{
    uint c = cursor;
    
    auto e = new DeclaraIdentificadorGlobal();
    
    if(auto id = identificador())
    {
        e.nombre = id.nombre;
        e.línea = id.línea;
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

    if(auto n = reservada("global"))
    {
        e.ámbito = "global";
    }
    else if(auto n = reservada("externo"))
    {
        e.ámbito = "externo";
    }
    else
    {
        cursor = c;
        return null;
    }

    if(auto t = tipo())
    {
        e.tipo = t.tipo;
        return e;
    }
    else
    {
        cursor = c;
        return null;
    }
}


//DEF_ID_GLOB := ID = (global | constante) LITERAL
private DefineIdentificadorGlobal define_identificador_global()
{
    uint c = cursor;
    
    auto i = new DefineIdentificadorGlobal();

    if(auto id = identificador())
    {
        i.nombre = id.nombre;
        i.línea = id.línea;
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

    if(auto n = reservada("global"))
    {
        i.ámbito = "global";
    }
    else if(auto n = reservada("constante"))
    {
        i.ámbito = "constante";
    }
    else
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


//DEF_ID_LOC := ID = (local | constante) LITERAL
private DefineIdentificadorLocal define_identificador_local()
{
    uint c = cursor;
    
    auto i = new DefineIdentificadorLocal();

    if(auto id = identificador())
    {
        i.nombre = id.nombre;
        i.línea = id.línea;
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

    if(auto n = reservada("local"))
    {
        i.ámbito = "local";
    }
    else if(auto n = reservada("constante"))
    {
        i.ámbito = "constante";
    }
    else
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
    else if(Nodo f = llama_función())
    {
        r2 = f;
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

            if(símbolos[cursor].categoría == lexema_e.RESERVADA)
            {
                lexema l = símbolos[cursor];

                Nodo r = reservada(l.símbolo);
                o.ramas ~= r;
            }

            if(LlamaFunción f = llama_función())
            {
                o.ramas ~= f;
            }
            else if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Literal l = literal())
            {
                o.ramas ~= l;
            }
            else if(auto e = etiqueta())
            {
                o.ramas ~= e;
            }
            else if(auto t = tipo())
            {
                int c1 = cursor;
                // para el nodo phi
                // %id = phi <tipo> [valor, etiqueta], ...

                while(true)
                {
                    if(!notación("["))
                    {
                        // esperaba una dupla
                        cursor = c1;
                        break;
                    }
                    
                    Literal lit;
                    Etiqueta eti;



                    if(auto num = número())
                    {
                        lit = new Literal();
                        lit.dato = num.dato;
                        lit.tipo = t.tipo;
                        lit.línea = t.línea;
                    }

                    if(!notación(","))
                    {
                        // esperaba una coma
                        cursor = c1;
                        break;
                    }

                    if(auto e = etiqueta())
                    {
                        eti = e;
                    }
                    else
                    {
                        cursor = c1;
                        break;
                    }

                    if(!notación("]"))
                    {
                        cursor = c1;
                        break;
                    }
                    else
                    {
                        o.ramas ~= lit;
                        o.ramas ~= eti;
                    }

                    writeln("PRUEBA");

                    if(!notación(","))
                    {
                        break;
                    }
                }

                return o;
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
                else if(Literal l = literal())
                {
                    o.ramas ~= l;
                    continue;
                }
                else if(auto e = etiqueta())
                {
                    o.ramas ~= e;
                }
                else cursor = c1;

                break;
            }

            if(símbolos[cursor].categoría == lexema_e.RESERVADA)
            {
                if(reservada("a") !is null)
                {
                    auto n = tipo();
                    auto t = new Tipo();
                    t.tipo = n.tipo;
                    t.línea = n.línea;
                    o.ramas ~= t;
                }
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
            Identificador id = new Identificador();
            id.nombre = símbolos[cursor].símbolo;
            id.línea = símbolos[cursor].línea;
            
            cursor++;
            return id;
        }
    }

    cursor = c;
    return null;
}


//LLAMA_FUNCIÓN -- TIPO IDENTIFICADOR '(' [ (LITERAL | IDENTIFICADOR) [, (LITERAL | IDENTIFICADOR) ]* ] ')'
private LlamaFunción llama_función()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        LlamaFunción  f  = new LlamaFunción();

        if(Tipo t = tipo())
        {
            f.tipo = t.tipo;
        }
        else
        {
            cursor = c;
            return null;
        }

        if(símbolos[cursor].categoría != lexema_e.IDENTIFICADOR)
        {
            cursor = c;
            return null;
        }

        if(Identificador r = identificador())
        {
            f.nombre = r.nombre;
            f.línea = r.línea;
        }
        else
        {
            return null;
        }

        if(!(notación("(")))
        {
            return null;
        }
        

        if(Identificador i = identificador())
        {
            f.ramas ~= i;
        }
        else if(Literal l = literal())
        {
            f.ramas ~= l;
        }
        else if(notación(")"))
        {
            return f;
        }
        else
        {
            cursor = c;
            return null;
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
                f.ramas ~= i;
                continue;
            }
            else if(Literal l = literal())
            {
                f.ramas ~= l;
                continue;
            }
            else cursor = c1;

            break;
        }

        if(notación(")"))
        {
            return f;
        }
        else
        {
            cursor = c;
            return null;
        }
    }

    cursor = c;
    return null;
}

//LITERAL -- TIPO ['+' | '-'] NÚMERO
private Literal literal()
{
    uint c = cursor;

    if(Tipo t = tipo())
    {
        if((cast(Tipo)t).tipo == "nada")
        {
            return null;
        }

        auto l = new Literal();

        if(Nodo signo = notación("+"))
        {
            // el literal es positivo
        }
        else if(Nodo signo = notación("-"))
        {
            l.dato = "-";
        }
                
        if(Nodo n = número())
        {
            l.tipo = t.tipo;
            l.dato ~= n.dato;
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


//TIPO -- lexema_e.TIPO, dstring nada|n|e|r+Nº, uint64_t línea
private Tipo tipo()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.TIPO)
        {
            Tipo t = new Tipo();
            t.categoría = Categoría.TIPO;
            t.tipo = símbolos[cursor].símbolo;
            t.línea = símbolos[cursor].línea;
            
            cursor++;
            return t;
        }
    }

    cursor = c;
    return null;
}


private Nodo nombre()
{
    if(cursor >= símbolos.length)
    {
        if(CHARLATÁN)
        {
            write("CHARLATÁN: he llegado al final del archivo buscando un nombre");
        }
        
        return null;
    }

    if(símbolos[cursor].categoría == lexema_e.NOMBRE)
    {
        if(CHARLATÁN)
        {
            //writeln("not["d ~ símbolos[cursor].símbolo ~ "]"d);
        }

        Nodo n = new Nodo();
        n.dato = símbolos[cursor].símbolo;
        n.línea = símbolos[cursor].línea;

        cursor++;
        return n;
    }

    return null;
}

private Etiqueta etiqueta()
{
    int c = cursor;
    
    if(símbolos[cursor].categoría == lexema_e.ETIQUETA)
    {
        if(CHARLATÁN)
        {
            //writeln("not["d ~ símbolos[cursor].símbolo ~ "]"d);
        }

        auto e = new Etiqueta();

        // Convierto el texto de la etiqueta para que todas tengan
        // la estructura ':etiqueta'

        dstring txt = ":";

        for(int i = 0; i<símbolos[cursor].símbolo.length; i++)
        {
            if(símbolos[cursor].símbolo[i] != ':')
            {
                txt ~= símbolos[cursor].símbolo[i];
            }
        }

        e.dato = txt;
        e.línea = símbolos[cursor].línea;
        
        cursor++;
        return e;
    }

    cursor = c;
    return null;
}


private Reservada reservada(dstring txt)
{
    if(cursor >= símbolos.length)
    {
        if(CHARLATÁN)
        {
            write("CHARLATÁN: he llegado al final del archivo y buscaba '");
            write(txt);
            writeln("'");
        }
        
        return null;
    }

    if((símbolos[cursor].categoría == lexema_e.RESERVADA) && (símbolos[cursor].símbolo == txt))
    {
        if(CHARLATÁN)
        {
            //writeln("not["d ~ txt ~ "]"d);
        }

        Reservada n = new Reservada();
        n.dato = txt;
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
        if(CHARLATÁN)
        {
            write("CHARLATÁN: he llegado al final del archivo y buscaba '");
            write(c);
            writeln("'");
        }
        
        return null;
    }

    if((símbolos[cursor].categoría == lexema_e.NOTACIÓN) && (símbolos[cursor].símbolo == c))
    {
        Nodo n = new Nodo();
        n.línea = símbolos[cursor].línea;

        cursor++;
        return n;
    }

    return null;
}


private bool fda()
{
    return (símbolos[cursor].categoría == lexema_e.FDA);
}
