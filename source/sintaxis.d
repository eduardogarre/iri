module sintaxis;

dstring nombre_módulo = "Sintaxis.d";

import apoyo;
import arbol;
import std.conv;
import std.stdint;
import std.stdio;


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
        aborta(nombre_módulo, símbolos[cursor].línea, "Esperaba llegar al final del"
        ~ " archivo, pero me encuentro en [" ~ símbolos[cursor].símbolo ~ "]");
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
            df.retorno = r;
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
            if(r !is null)
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

    if(auto n = reservada("privado"))
    {
        e.ámbito = "privado";
    }
    else if(auto n = reservada("público"))
    {
        e.ámbito = "público";
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
        e.tipo = t;
        return e;
    }
    else
    {
        cursor = c;
        return null;
    }
}


//DEF_ID_GLOB := ID = (privado | público) LITERAL
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

    if(auto n = reservada("privado"))
    {
        i.ámbito = "privado";
    }
    else if(auto n = reservada("público"))
    {
        i.ámbito = "público";
    }
    else if(auto n = reservada("externo"))
    {
        i.ámbito = "externo";
    }
    else
    {
        i.ámbito = "";
    }

    if(auto ti = tipo())
    {
        i.tipo = ti;
    }
    else if(auto l = texto())
    {
        i.ramas ~= l;
        return i;
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


//OPERACIÓN -- OP_ARITM|RET|CONV|CMP|SLT|PHI|LLAMA|RSRVA|GUARDA|LEE
private Operación operación()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        // El lexema es de una operación
        if(símbolos[cursor].categoría == lexema_e.OPERACIÓN)
        {
            Operación o;

            o = op_aritmética();
            if(o !is null)
            {
                return o;
            }

            o = op_ret();
            if(o !is null)
            {
                return o;
            }

            o = op_conv();
            if(o !is null)
            {
                return o;
            }

            o = op_cmp();
            if(o !is null)
            {
                return o;
            }

            o = op_slt();
            if(o !is null)
            {
                return o;
            }

            o = op_phi();
            if(o !is null)
            {
                return o;
            }

            o = op_llama();
            if(o !is null)
            {
                return o;
            }

            o = op_rsrva();
            if(o !is null)
            {
                return o;
            }

            o = op_lee();
            if(o !is null)
            {
                return o;
            }

            o = op_guarda();
            if(o !is null)
            {
                return o;
            }

            o = op_leeval();
            if(o !is null)
            {
                return o;
            }

            o = op_ponval();
            if(o !is null)
            {
                return o;
            }

            // Si llegamos hasta aquí, nos encontramos ante un lexema de
            // una operación que no hemos sabido identificar.

            aborta(nombre_módulo, símbolos[cursor].línea, "operación() - No reconozco el op '" ~ símbolos[cursor].símbolo ~ "'");
        }
    }

    cursor = c;
    return null;
}


//OPERACIÓN -- (sum|res|mul|div) TIPO (ID | LITERAL), (ID | LITERAL)
private Operación op_aritmética()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.OPERACIÓN)
        {
            
            Operación o = new Operación();

            o.dato = símbolos[cursor].símbolo;
            o.línea = símbolos[cursor].línea;

            if( (o.dato != "sum")
             && (o.dato != "res")
             && (o.dato != "mul")
             && (o.dato != "div")
            )
            {
                return null;
            }

            cursor++;

            if(auto t = tipo())
            {
                o.ramas ~= t;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_aritmética() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Tipo'");
                return null;
            }

            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Nodo l = literal())
            {
                o.ramas ~= l;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_aritmética() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Identificador' o 'Literal'");
                return null;
            }

            if(!notación(","))
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_aritmética() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba ','");
                cursor = c;
                return null;
            }

            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Nodo l = literal())
            {
                o.ramas ~= l;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_aritmética() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Identificador' o 'Literal'");
                return null;
            }

            if(notación(";"))
            {
                cursor--;
                return o;
            }
        }
    }

    cursor = c;
    return null;
}


//OPERACIÓN -- conv TIPO1 (ID | LITERAL) a TIPO2
private Operación op_conv()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.OPERACIÓN)
        {
            
            Operación o = new Operación();

            o.dato = símbolos[cursor].símbolo;
            o.línea = símbolos[cursor].línea;

            if(o.dato != "conv")
            {
                return null;
            }

            cursor++;

            if(auto t = tipo())
            {
                o.ramas ~= t;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_conv() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Tipo'");
                return null;
            }

            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Nodo l = literal())
            {
                o.ramas ~= l;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_conv() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Identificador' o 'Literal'");
                return null;
            }

            if(!reservada("a"))
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_conv() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'a'");
                cursor = c;
                return null;
            }

            

            if(auto ti = tipo())
            {
                o.ramas ~= ti;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_conv() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Tipo'");
                return null;
            }

            if(notación(";"))
            {
                cursor--;
                return o;
            }
        }
    }

    cursor = c;
    return null;
}


//OPERACIÓN -- ret [TIPO (ID | LITERAL)]
private Operación op_ret()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.OPERACIÓN)
        {
            
            Operación o = new Operación();

            o.dato = símbolos[cursor].símbolo;
            o.línea = símbolos[cursor].línea;

            if(o.dato != "ret")
            {
                return null;
            }

            cursor++;

            if(auto t = tipo())
            {
                o.ramas ~= t;

                // ret TIPO ID;
                if(Identificador i = identificador())
                {
                    o.ramas ~= i;
                }
                // ret TIPO LITERAL;
                else if(Nodo l = literal())
                {
                    o.ramas ~= l;
                }
                else // Error.
                {
                    aborta(nombre_módulo, símbolos[cursor].línea, "op_ret() - "
                    ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                    ~ "correcta. Esperaba 'Identificador' o 'Literal'");
                    return null;
                }
                
                if(notación(";"))// ret;
                {
                    cursor--;
                    return o;
                }
            }
            else if(notación(";"))// ret;
            {
                cursor--;
                return o;
            }
        }
    }

    cursor = c;
    return null;
}


//OPERACIÓN -- cmp COMPARACIÓN TIPO (ID | LITERAL), (ID | LITERAL)
private Operación op_cmp()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.OPERACIÓN)
        {
            Operación o = new Operación();
            Tipo t;

            o.dato = símbolos[cursor].símbolo;
            o.línea = símbolos[cursor].línea;

            // comprueba que el cod_op es 'cmp'
            if(o.dato != "cmp")
            {
                return null;
            }

            cursor++;

            // comprueba que se indica qué comparación hay que realizar
            if(auto r = reservada("ig")) // igualdad
            {
                o.ramas ~= r;
            }
            else if(auto r = reservada("dsig")) // desigualdad
            {
                o.ramas ~= r;
            }
            else if(auto r = reservada("ma")) // mayor que
            {
                o.ramas ~= r;
            }
            else if(auto r = reservada("me")) // menor que
            {
                o.ramas ~= r;
            }
            else if(auto r = reservada("maig")) // mayor o igual que
            {
                o.ramas ~= r;
            }
            else if(auto r = reservada("meig")) // menor o igual
            {
                o.ramas ~= r;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_cmp() - "
                ~ "La estructura de la operación 'cmp' no es correcta. "
                ~ "Esperaba 'Comparación'");
                return null;
            }

            if(auto ti = tipo())
            {
                t = ti;
                o.ramas ~= t;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_cmp() - "
                ~ "La estructura de la operación 'cmp' no es correcta. "
                ~ "Esperaba 'Tipo'");
                return null;
            }

            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Nodo l = literal())
            {
                o.ramas ~= l;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_cmp() - "
                ~ "La estructura de la operación 'cmp' no es correcta. "
                ~ "Esperaba 'Literal' o 'Identificador'");
                return null;
            }

            if(!notación(","))
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_cmp() - "
                ~ "La estructura de la operación 'cmp' no es correcta. "
                ~ "Esperaba ','");
                
                cursor = c;
                return null;
            }

            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Nodo l = literal())
            {
                o.ramas ~= l;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_cmp() - "
                ~ "La estructura de la operación 'cmp' no es correcta. "
                ~ "Esperaba 'Literal' o 'Identificador'");
                return null;
            }

            if(notación(";"))
            {
                cursor--;
                return o;
            }
        }
    }

    cursor = c;
    return null;
}


//OPERACIÓN -- slt [TIPO (ID | LITERAL),] ETIQUETA
private Operación op_slt()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.OPERACIÓN)
        {
            Operación o = new Operación();

            o.dato = símbolos[cursor].símbolo;
            o.línea = símbolos[cursor].línea;

            // comprueba que el cod_op es 'slt'
            if(o.dato != "slt")
            {
                return null;
            }

            cursor++;

            if(auto e = etiqueta())
            {
                o.ramas ~= e;
                return o;
            }

            if(auto t = tipo())
            {
                o.ramas ~= t;

                if(Identificador i = identificador())
                {
                    o.ramas ~= i;
                }
                else if(Nodo n = literal())
                {
                    auto l = new Literal();
                    l.dato = n.dato;
                    l.tipo = t.tipo;
                    o.ramas ~= l;
                }
                else // Error.
                {
                    aborta(nombre_módulo, símbolos[cursor].línea, "op_slt() - "
                    ~ "La estructura de la operación 'slt' no es correcta. "
                    ~ "Esperaba 'Literal' o 'Identificador'");
                    return null;
                }

                if(!notación(","))
                {
                    aborta(nombre_módulo, símbolos[cursor].línea, "op_slt() - "
                    ~ "La estructura de la operación 'slt' no es correcta. "
                    ~ "Esperaba ','");
                    
                    cursor = c;
                    return null;
                }

                if(auto e = etiqueta())
                {
                    o.ramas ~= e;

                    if(notación(";"))
                    {
                        cursor--;
                        return o;
                    }
                }
                else // Error.
                {
                    aborta(nombre_módulo, símbolos[cursor].línea, "op_slt() - "
                    ~ "La estructura de la operación 'slt' no es correcta. "
                    ~ "Esperaba 'Etiqueta'");
                    return null;
                }
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_slt() - "
                ~ "La estructura de la operación 'slt' no es correcta. "
                ~ "Esperaba 'Tipo'");
                return null;
            }
        }
    }

    cursor = c;
    return null;
}


//OPERACIÓN -- phi TIPO '['(ID | LITERAL), ETIQUETA']', [ '['(ID | LITERAL), ETIQUETA']' ]
private Operación op_phi()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.OPERACIÓN)
        {
            
            Operación o = new Operación();

            o.dato = símbolos[cursor].símbolo;
            o.línea = símbolos[cursor].línea;

            if(o.dato != "phi")
            {
                return null;
            }

            cursor++;

            if(auto t = tipo())
            {
                o.ramas ~= t;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_phi() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Tipo'");
                return null;
            }

            if(!notación("["))
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_phi() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba ^[Literal, Etiqueta], o bien "
                ~ "^[Identificador, Etiqueta]");
                return null;
            }
            
            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Nodo l = literal())
            {
                o.ramas ~= l;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_phi() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 1er 'Identificador' o 'Literal'");
                return null;
            }

            if(!notación(","))
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_phi() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba [Literal^, Etiqueta], o bien "
                ~ "[Identificador^, Etiqueta]");
                return null;
            }
            
            if(auto e = etiqueta())
            {
                o.ramas ~= e;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_phi() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Etiqueta'");
                return null;
            }

            if(!notación("]"))
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_phi() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba ^[Literal, Etiqueta], o bien "
                ~ "^[Identificador, Etiqueta]");
                return null;
            }

            while(true)
            {
                if(!notación(","))
                {
                    break;
                }

                if(!notación("["))
                {
                    aborta(nombre_módulo, símbolos[cursor].línea, "op_phi() - "
                    ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                    ~ "correcta. Esperaba ^[Literal, Etiqueta], o bien "
                    ~ "^[Identificador, Etiqueta]");
                    return null;
                }
                
                if(Identificador i = identificador())
                {
                    o.ramas ~= i;
                }
                else if(Nodo l = literal())
                {
                    o.ramas ~= l;
                }
                else // Error.
                {
                    aborta(nombre_módulo, símbolos[cursor].línea, "op_phi() - "
                    ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                    ~ "correcta. Esperaba 'Identificador' o 'Literal'");
                    return null;
                }

                if(!notación(","))
                {
                    aborta(nombre_módulo, símbolos[cursor].línea, "op_phi() - "
                    ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                    ~ "correcta. Esperaba [Literal^, Etiqueta], o bien "
                    ~ "[Identificador^, Etiqueta]");
                    return null;
                }
            
                if(auto e = etiqueta())
                {
                    o.ramas ~= e;
                }
                else // Error.
                {
                    aborta(nombre_módulo, símbolos[cursor].línea, "op_phi() - "
                    ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                    ~ "correcta. Esperaba 'Identificador' o 'Literal'");
                    return null;
                }

                if(!notación("]"))
                {
                    aborta(nombre_módulo, símbolos[cursor].línea, "op_phi() - "
                    ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                    ~ "correcta. Esperaba [Literal, Etiqueta^], o bien "
                    ~ "[Identificador, Etiqueta^]");
                    return null;
                }
            }

            if(notación(";"))// ret;
            {
                cursor--;
                return o;
            }
        }
    }

    cursor = c;
    return null;
}


//OPERACIÓN -- llama TIPO FUNCIÓN '(' [ARGS] ')'
private Operación op_llama()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.OPERACIÓN)
        {
            
            Operación o = new Operación();
            Tipo t;

            o.dato = símbolos[cursor].símbolo;
            o.línea = símbolos[cursor].línea;

            if(o.dato != "llama")
            {
                return null;
            }

            cursor++;

            if(LlamaFunción f = llama_función())
            {
                o.ramas ~= f;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_llama() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba '@función()' [línea:" ~ to!dstring(o.línea)
                ~ "]");
                return null;
            }

            if(notación(";"))// ret;
            {
                cursor--;
                return o;
            }
            else
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_llama() - "
                ~ "Debería haber llegado al final de la operación '"
                ~ o.dato ~ "', sin embargo, no he encontrado un ';'");
            }
        }
    }

    cursor = c;
    return null;
}


//OPERACIÓN -- rsrva TIPO
private Operación op_rsrva()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.OPERACIÓN)
        {
            
            Operación o = new Operación();

            o.dato = símbolos[cursor].símbolo;
            o.línea = símbolos[cursor].línea;

            if(o.dato != "rsrva")
            {
                return null;
            }

            cursor++;

            if(auto t = tipo())
            {
                o.ramas ~= t;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_rsrva() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Tipo'");
                return null;
            }
                
            if(notación(";"))// ret;
            {
                cursor--;
                return o;
            }
        }
    }

    cursor = c;
    return null;
}


//OPERACIÓN -- lee TIPO, TIPO * (ID | LITERAL)
private Operación op_lee()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.OPERACIÓN)
        {
            
            Operación o = new Operación();

            o.dato = símbolos[cursor].símbolo;
            o.línea = símbolos[cursor].línea;

            if(o.dato != "lee")
            {
                return null;
            }

            cursor++;

            if(auto t = tipo())
            {
                o.ramas ~= t;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_lee() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Tipo1'");
                return null;
            }

            if(!notación(",")) // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_lee() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba ','");
                return null;
            }

            if(auto t = tipo())
            {
                o.ramas ~= t;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_lee() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Tipo2'");
                return null;
            }

            if(!notación("*")) // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_lee() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba '*'");
                return null;
            }
            
            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Nodo l = literal())
            {
                o.ramas ~= l;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_lee() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 1er 'Identificador' o 'Literal'");
                return null;
            }
                
            if(notación(";"))
            {
                cursor--;
                return o;
            }
        }
    }

    cursor = c;
    return null;
}


//OPERACIÓN -- guarda TIPO (DATO|IDENTIFICADOR), TIPO* (DATO|IDENTIFICADOR)
private Operación op_guarda()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.OPERACIÓN)
        {
            Operación o = new Operación();

            o.dato = símbolos[cursor].símbolo;
            o.línea = símbolos[cursor].línea;

            if(o.dato != "guarda")
            {
                return null;
            }

            cursor++;

            if(auto t = tipo())
            {
                o.ramas ~= t;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_guarda() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Tipo1'");
                return null;
            }
            
            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Nodo l = literal())
            {
                o.ramas ~= l;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_guarda() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 1er 'Identificador' o 'Literal'");
                return null;
            }

            if(!notación(",")) // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_guarda() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba ','");
                return null;
            }

            if(auto t = tipo())
            {
                o.ramas ~= t;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_guarda() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Tipo2'");
                return null;
            }

            if(!notación("*")) // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_guarda() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba '*'");
                return null;
            }
            
            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Nodo l = literal())
            {
                o.ramas ~= l;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_guarda() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 1er 'Identificador' o 'Literal'");
                return null;
            }
            
            if(notación(";"))
            {
                cursor--;
                return o;
            }
        }
    }

    cursor = c;
    return null;
}


//OPERACIÓN -- %x = leeval <tipo_vector> <literal_vector>, <índice>
private Operación op_leeval()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.OPERACIÓN)
        {
            Operación o = new Operación();

            o.dato = símbolos[cursor].símbolo;
            o.línea = símbolos[cursor].línea;

            if(o.dato != "leeval")
            {
                return null;
            }

            cursor++;

            Tipo t = tipo();
            if((t !is null) && (t.vector || t.estructura))
            {
                o.ramas ~= t;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_leeval() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Tipo' conteniendo 'Vector' ó 'Estructura'");
                return null;
            }
            
            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Nodo l = literal())
            {
                o.ramas ~= l;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_leeval() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 1er 'Identificador' o 'Literal'");
                return null;
            }

            if(!notación(",")) // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_leeval() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba ','");
                return null;
            }
            
            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Nodo l = literal())
            {
                o.ramas ~= l;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_leeval() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Indice'");
                return null;
            }
            
            if(notación(";"))
            {
                cursor--;
                return o;
            }
        }
    }

    cursor = c;
    return null;
}


//OPERACIÓN -- %x = ponval <tipo_vector> <literal_vector>, <tipo> <literal>, <índice>
private Operación op_ponval()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        if(símbolos[cursor].categoría == lexema_e.OPERACIÓN)
        {
            Operación o = new Operación();

            o.dato = símbolos[cursor].símbolo;
            o.línea = símbolos[cursor].línea;

            if(o.dato != "ponval")
            {
                return null;
            }

            cursor++;

            
            if(Tipo t = tipo())
            {
                if(t.vector || t.estructura)
                {
                    o.ramas ~= t;
                }
                else
                {
                    aborta(nombre_módulo, símbolos[cursor].línea, "op_ponval() - "
                    ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                    ~ "correcta. Esperaba 'Tipo' conteniendo 'Vector' ó 'Estructura'");
                    return null;
                }
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_ponval() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Tipo' conteniendo 'Vector'");
                return null;
            }
            
            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Nodo l = literal())
            {
                o.ramas ~= l;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_ponval() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 1er 'Identificador' o 'Literal'");
                return null;
            }

            if(!notación(",")) // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_ponval() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba ','");
                return null;
            }

            if(Tipo t = tipo())
            {
                o.ramas ~= t;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_ponval() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Tipo'");
                return null;
            }
            
            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Nodo l = literal())
            {
                o.ramas ~= l;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_ponval() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 1er 'Identificador' o 'Literal'");
                return null;
            }

            if(!notación(",")) // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_ponval() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba ','");
                return null;
            }
            
            if(Identificador i = identificador())
            {
                o.ramas ~= i;
            }
            else if(Nodo l = literal())
            {
                o.ramas ~= l;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "op_ponval() - "
                ~ "La estructura de la operación '" ~ o.dato ~ "' no es "
                ~ "correcta. Esperaba 'Indice'");
                return null;
            }
            
            if(notación(";"))
            {
                cursor--;
                return o;
            }
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

//LITERAL -- NÚMERO
private Literal literal()
{
    uint c = cursor;

    Literal l = new Literal();

    if(Nodo n = número())
    {
        l.dato = n.dato;
        l.tipo = "número";
        l.línea = n.línea;

        return l;
    }
    else if(Nodo n = carácter())
    {
        uint32_t dato = unsigned(n.dato[0]);
        if(n.dato == "\0")
        {
            dato = 0;
        }

        l.dato = to!dstring(dato);
        l.tipo = "";
        l.línea = n.línea;

        return l;
    }
    else if(Literal lit = vector())
    {
        return lit;
    }
    else if(Literal lit = estructura())
    {
        return lit;
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
        Nodo n = new Nodo();

        if(Nodo signo = notación("+"))
        {
            // el literal es positivo
        }
        else if(Nodo signo = notación("-"))
        {
            n.dato = "-";
        }

        if(símbolos[cursor].categoría == lexema_e.NÚMERO)
        {
            n.categoría = Categoría.NÚMERO;
            n.dato ~= símbolos[cursor].símbolo;
            n.línea = símbolos[cursor].línea;

            cursor++;
            return n;
        }
    }

    cursor = c;
    return null;
}


//CARÁCTER -- lexema_e.CARÁCTER
private Nodo carácter()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        Nodo n = new Nodo();

        if(símbolos[cursor].categoría == lexema_e.CARÁCTER)
        {
            n.categoría = Categoría.CARÁCTER;
            n.dato = símbolos[cursor].símbolo;
            n.línea = símbolos[cursor].línea;

            cursor++;
            return n;
        }
    }

    cursor = c;
    return null;
}


//TEXTO -- "..."
private Literal texto()
{
    int c = cursor;
    
    if(símbolos[cursor].categoría == lexema_e.TEXTO)
    {
        Literal l = new Literal();
        l.vector = true;

        foreach(car; símbolos[cursor].símbolo)
        {
            Literal lit = new Literal();

            uint32_t dato = unsigned(car);
            lit.dato = to!dstring(dato);

            l.ramas ~= lit;
        }

        // añado el fin de cadena '\0'
        
        Literal lit = new Literal();

        uint32_t dato = unsigned('\0');
        lit.dato = to!dstring(dato);

        l.ramas ~= lit;

        cursor++;

        return l;
    }

    cursor = c;
    return null;
}


//VECTOR -- Literal de un vector
private Literal vector()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        Literal l = new Literal();
        l.vector = true;

        if(!notación("["))
        {
            cursor = c;
            return null;
        }
    
        if(Identificador i = identificador())
        {
            l.ramas ~= i;
        }
        else if(Literal lit = literal())
        {
            if((lit.tipo == "carácter") && (lit.dato.length == 1))
            {
                uint32_t dato = unsigned(lit.dato[0]);
                lit.dato = to!dstring(dato);
            }
            lit.tipo = "";
            
            l.ramas ~= lit;
        }
        else // Error.
        {
            aborta(nombre_módulo, símbolos[cursor].línea, "vector() - "
                ~ "Literal de Vector: Esperaba 'Identificador' o 'Literal'");
            return null;
        }

        while(true)
        {
            if(!notación(","))
            {
                break;
            }

            if(Identificador i = identificador())
            {
                l.ramas ~= i;
            }
            else if(Literal lit = literal())
            {
                if((lit.tipo == "carácter") && (lit.dato.length == 1))
                {
                    uint32_t dato = unsigned(lit.dato[0]);
                    lit.dato = to!dstring(dato);
                }
                lit.tipo = "";
            
                l.ramas ~= lit;
            }
            else // Error.
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "vector() - "
                ~ "Literal de Vector: Esperaba 'Identificador' o 'Literal'");
                return null;
            }
        }

        if(!notación("]"))
        {
            aborta(nombre_módulo, símbolos[cursor].línea, "vector() - "
                ~ "Literal de Vector: Esperaba ']'");
            return null;
        }

        return l;
    }

    cursor = c;
    return null;
}


//ESTRUCTURA -- Literal de una estructura
private Literal estructura()
{
    uint c = cursor;

    if(cursor < símbolos.length)
    {
        Literal l = new Literal();
        l.estructura = true;

        if(!notación("{"))
        {
            cursor = c;
            return null;
        }
    
        if(Identificador id = identificador())
        {
            l.ramas ~= id;
        }
        else if(Literal li = literal())
        {
            l.ramas ~= li;
        }
        else
        {
            aborta(nombre_módulo, símbolos[cursor].línea, "estructura() - "
                ~ "Esperaba 'Literal' ó 'Id': {dato}");
            cursor = c;
            return null;
        }

        while(notación(","))
        {
            if(Identificador id = identificador())
            {
                l.ramas ~= id;
            }
            else if(Literal li = literal())
            {
                l.ramas ~= li;
            }
            else
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "estructura() - "
                ~ "Esperaba 'Literal' ó 'Id': {dato, ...}");
                cursor = c;
                return null;
            }
        }

        if(!notación("}"))
        {
            aborta(nombre_módulo, símbolos[cursor].línea, "estructura() - "
                ~ "Esperaba '}': {dato, ...}");
            cursor = c;
            return null;
        }

        return l;
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
        else if(notación("[")) // vector
        {
            Tipo t = new Tipo();
            t.vector = true;

            if(auto elementos = número())
            {
                t.elementos = elementos.dato;
                t.línea = elementos.línea;
            }
            else
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "tipo() - "
                ~ "Esperaba 'Número': [N x Tipo]");
                cursor = c;
                return null;
            }

            if(reservada("x") is null)
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "tipo() - "
                ~ "Esperaba 'x': [N x Tipo]");
                cursor = c;
                return null;
            }
            
            if(Tipo ti = tipo())
            {
                t.tipo = ti.tipo;
            }
            else
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "tipo() - "
                ~ "Esperaba 'Tipo': [N x Tipo]");
                cursor = c;
                return null;
            }

            if(!notación("]"))
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "tipo() - "
                ~ "Esperaba ']': [N x Tipo]");
                cursor = c;
                return null;
            }

            return t;
        }
        else if(notación("{")) // estructura
        {
            Tipo t = new Tipo();
            t.estructura = true;

            if(Tipo ti = tipo())
            {
                t.ramas ~= ti;
            }
            else
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "tipo() - "
                ~ "Esperaba 'Tipo': {Tipo}");
                cursor = c;
                return null;
            }

            while(notación(","))
            {
                if(Tipo ti = tipo())
                {
                    t.ramas ~= ti;
                }
                else
                {
                    aborta(nombre_módulo, símbolos[cursor].línea, "tipo() - "
                ~ "Esperaba 'Tipo': {Tipo}");
                    cursor = c;
                    return null;
                }
            }

            if(!notación("}"))
            {
                aborta(nombre_módulo, símbolos[cursor].línea, "tipo() - "
                ~ "Esperaba '}': {Tipo}");
                cursor = c;
                return null;
            }

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
