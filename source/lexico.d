module lexico;

dstring módulo = "Léxico.d";

import std.conv; // to!tipo()
import std.stdint;
import std.stdio;
import apoyo;

public dstring código  = "";

private lexema[] análisis;

public uint cursor = 0;
private uint64_t línea  = 1;


public lexema[] analiza(dstring cód)
{
    código = cód ~ "\n"d;
    línea = 1;
    
    while(cursor < código.length)
    {
        uint c = cursor;
        if(nuevalínea())
        {
            continue;
        }
        cursor = c;

        if(espacio())
        {
            continue;
        }
        cursor = c;

        if(comentario1L())
        {
            continue;
        }
        cursor = c;

        if(comentarioXL())
        {
            continue;
        }
        cursor = c;

        if(etiqueta())
        {
            continue;
        }
        cursor = c;

        if(notación())
        {
            continue;
        }
        cursor = c;

        if(reservada())
        {
            continue;
        }
        cursor = c;

        if(número())
        {
            continue;
        }
        cursor = c;

        if(carácter())
        {
            continue;
        }
        cursor = c;

        if(texto())
        {
            continue;
        }
        cursor = c;

        if(tipo())
        {
            continue;
        }
        cursor = c;

        if(identificador())
        {
            continue;
        }
        cursor = c;

        if(operación())
        {
            continue;
        }
        cursor = c;

        if(nombre())
        {
            continue;
        }
        cursor = c;

        break;
    }

    lexema fda;
    fda.categoría = lexema_e.FDA;
    fda.línea = línea;

    análisis ~= fda;

    return análisis;
}

private bool nuevalínea()
{
    bool resultado = false;
    uint c = cursor;
    uint i;
    if(mismocarácter(código[cursor], '\n'))
    {
        resultado = true;
        cursor++;
        línea++;
    }
    else
    {
        cursor = c;
        return false;
    }

    return resultado;
}

private bool espacio()
{
    bool resultado = false;


    if(esespacio(código[cursor]))
    {
        resultado = true;
        do {
            if(cursor == (código.length - 1))
            {
                return false;
            }
            nuevalínea();
            cursor++;
        } while(esespacio(código[cursor]));
    }

    if(resultado)
    {
        //emiteln("ESPACIO");
    }

    return resultado;
}

private bool comentario1L()
{
    bool resultado = false;
    if(mismocarácter(código[cursor],'/'))
    {
        const uint c = cursor;
        cursor++;
        if(mismocarácter(código[cursor],'/'))
        {
            resultado = true;
            do {
                cursor++;
            } while(!nuevalínea());

            //emiteln("COMENTARIO 1L");
        }
        else
        {
            cursor = c;
        }
    }

    return resultado;
}

private bool comentarioXL()
{
    bool resultado = false;
    uint c = cursor;
    if(_abrecomentarioXL())
    {
        resultado = true;
        do {
            if(!nuevalínea())
            {
                cursor++;
            }
        } while(!_cierracomentarioXL());

        //emiteln("COMENTARIO XL");

        resultado = true;
    }
    else
    {
        cursor = c;
    }

    return resultado;
}

private bool _abrecomentarioXL()
{
    bool resultado = false;
    if(mismocarácter(código[cursor],'/'))
    {
        uint c = cursor;
        cursor++;
        if(mismocarácter(código[cursor],'*'))
        {
            resultado = true;
        }
        else
        {
            cursor = c;
        }
    }
    return resultado;
}

private bool _cierracomentarioXL()
{
    bool resultado = false;
    if(mismocarácter(código[cursor],'*'))
    {
        uint c = cursor;
        cursor++;
        if(mismocarácter(código[cursor],'/'))
        {
            resultado = true;
            cursor++;
        }
        else
        {
            cursor = c;
        }
    }
    return resultado;
}

private bool notación()
{
    if(   (código[cursor] == ',')
        //| (código[cursor] == '-')
        | (código[cursor] == ';')
        | (código[cursor] == '=')
        | (código[cursor] == '(')
        | (código[cursor] == ')')
        | (código[cursor] == '[')
        | (código[cursor] == ']')
        | (código[cursor] == '{')
        | (código[cursor] == '}')
        | (código[cursor] == '*')
        | (código[cursor] == '/')
        | (código[cursor] == '\\')
        )
    {

        lexema l;
        l.categoría = lexema_e.NOTACIÓN;
        l.símbolo  ~= código[cursor];
        l.línea     = línea;

        análisis ~= l;

        cursor++;
        return true;
    }
    else
    {
        return false;
    }
}

private bool reservada()
{
    bool resultado = false;

    uint c = cursor;

    if(_nombre())
    {
        dstring s = código[c..cursor];

        if((s == "cierto")
         | (s == "falso")
         | (s == "público")
         | (s == "privado")
         | (s == "declara")
         | (s == "define")
         | (s == "externo")
         | (s == "módulo")
         | (s == "a") // op:conv %a a e32;
         | (s == "ig") // igual
         | (s == "dsig") // desigualdad
         | (s == "ma") // mayor
         | (s == "me") // menor
         | (s == "maig") // mayor o igual
         | (s == "meig") // menor o igual
         | (s == "x") // vectores: [4 x n8]
         | (s == "y")
         | (s == "o")
         | (s == "no")
         | (s == "oex")
         )
        {
            resultado = true;
            
            lexema l;
            l.categoría = lexema_e.RESERVADA;
            l.símbolo = s;
            l.línea = línea;

            análisis ~= l;
        }
        else
        {
            cursor = c;
        }
    }

    return resultado;
}

private bool etiqueta()
{
    int c = cursor;

    if(_nombre())
    {
        if(código[cursor] == ':')
        {
            cursor++;
            
            lexema l;
            l.categoría = lexema_e.ETIQUETA;
            l.símbolo = código[c..cursor];
            l.línea = línea;

            análisis ~= l;
            return true;
        }
    }

    cursor = c;

    if(código[cursor] == ':')
    {
        cursor++;
        if(_nombre())
        {
            lexema l;
            l.categoría = lexema_e.ETIQUETA;
            l.símbolo = código[c..cursor];
            l.línea = línea;

            análisis ~= l;
            return true;
        }
    }

    cursor = c;
    
    return false;
}

private bool _nombre()
{
    bool resultado = false;

    uint c = cursor;

    if(esletra(código[cursor]))
    {
        resultado = true;
        do {
            if(cursor == (código.length+1))
            {
                return true;
            }
            cursor++;
        } while(esalfanum(código[cursor]));
    }

    if(resultado)
    {
        /*
        dstring s = código[c..cursor];

        write("NOMBRE [ ");
        write(s);
        writeln(" ]");
        */
    }

    return resultado;
}

public bool número()
{
    if(_notacióncientífica())
    {
        return true;
    }
    else if(_númerodecimales())
    {
        return true;
    }
    else if(_número())
    {
        return true;
    }
    else
    {
        return false;
    }
}

private bool _notacióncientífica()
{
    bool resultado = false;

    uint c = cursor;

    if(código[cursor] == '-')
    {
        cursor++;
    }
        
    while(esdígito(código[cursor]) && (cursor < (código.length-1)))
    {
        resultado = true;
        cursor++;
    }

    if(código[cursor] != '.')
    {
        cursor = c;
        return false;
    }
    
    if(cursor == (código.length-1))
    {
        cursor = c;
        return false;
    }

    cursor++;

    do {
        resultado = true;
        cursor++;
    } while(esdígito(código[cursor]) && (cursor < (código.length-1)));

    dchar e = 'e';
    dchar E = 'E';
    if((código[cursor] != e) && (código[cursor] != E))
    {
        cursor = c;
        return false;
    }
    
    if(cursor == (código.length-1))
    {
        cursor = c;
        return false;
    }

    cursor++;
    
    if(cursor < (código.length-1) && (código[cursor] == '-') || (código[cursor] == '+') )
    {
        cursor++;
    }

    while(esdígito(código[cursor]) && (cursor < (código.length-1)))
    {
        resultado = true;
        cursor++;
    }

    if(resultado)
    {
        dstring s = código[c..cursor];

        //double n = to!double(s);

        lexema l;
        l.categoría = lexema_e.NÚMERO;
        l.símbolo   = s;
        l.línea     = línea;

        análisis ~= l;

        //emite("LITERAL REAL [ ");
        //write(n);
        //emiteln(" ]");

        //emiteln(código[c..cursor]);
    }

    return resultado;
}

private bool _númerodecimales()
{
    bool resultado = false;

    uint c = cursor;

    if(código[cursor] == '-')
    {
        cursor++;
    }
        
    while(esdígito(código[cursor]))
    {
        resultado = true;
        if(cursor == (código.length-1))
        {
            cursor = c;
            return false;
        }
        cursor++;
    }

    if(código[cursor] != '.')
    {
        cursor = c;
        return false;
    }
    
    if(cursor == (código.length-1))
    {
        cursor = c;
        return false;
    }
    
    cursor++;
        
    if(!esdígito(código[cursor]))
    {
        cursor = c;
        return false;
    }

    do {
        resultado = true;
        if(cursor == (código.length-1))
        {
            cursor = c;
            return false;
        }
        cursor++;
    } while(esdígito(código[cursor]));

    if(resultado)
    {
        dstring s = código[c..cursor];

        //double n = to!double(s);

        lexema l;
        l.categoría = lexema_e.NÚMERO;
        l.símbolo   = s;
        l.línea     = línea;

        análisis ~= l;
    }

    return resultado;
}

private bool _número()
{
    bool resultado = false;

    uint c = cursor;

    if(código[cursor] == '-')
    {
        cursor++;
    }

    if(esdígito(código[cursor]))
    {
        resultado = true;
        do {
            if(cursor == (código.length+1))
            {
                return true;
            }
            cursor++;
        } while(esdígito(código[cursor]));
    }

    if(resultado)
    {
        dstring s = código[c..cursor];

        //int n = to!int(s);

        lexema l;
        l.categoría = lexema_e.NÚMERO;
        l.símbolo   = s;
        l.línea     = línea;

        análisis ~= l;
    }

    return resultado;
}

private bool texto()
{
    if(mismocarácter(código[cursor],'\"'))
    {
        cursor++;
        uint c = cursor;

        dstring texto;

        lexema l;

        while((!mismocarácter(código[cursor],'\"')) && (cursor < código.length-1))
        {
            if(mismocarácter(código[cursor],'\\'))
            {
                cursor++;
                if(mismocarácter(código[cursor],'n'))
                {
                    texto ~= '\n';
                }
                else if(mismocarácter(código[cursor],'r'))
                {
                    texto ~= '\r';
                }
                else if(mismocarácter(código[cursor],'\''))
                {
                    texto ~= '\'';
                }
                else if(mismocarácter(código[cursor],'\"'))
                {
                    texto ~= '\"';
                }
                else if(mismocarácter(código[cursor],'\\'))
                {
                    texto ~= '\\';
                }
                else if(mismocarácter(código[cursor],'0'))
                {
                    texto ~= '\0';
                }
            }
            else
            {
                texto ~= to!dstring(código[cursor]);
            }
            
            cursor++;
        }

        l.categoría = lexema_e.TEXTO;
        l.símbolo   = texto;
        l.línea     = línea;

        if(!mismocarácter(código[cursor],'\"'))
        {
            cursor = c;
            esperaba(módulo, línea, "un cierre de comilla doble [\"]");
        }

        cursor++;

        análisis ~= l;

        return true;
    }
    else
    {
        return false;
    }
}

private bool carácter()
{
    if(mismocarácter(código[cursor],'\''))
    {
        cursor++;
        uint c = cursor;

        dstring car;

        lexema l;

        if(mismocarácter(código[cursor],'\\'))
        {
            cursor++;
            if(mismocarácter(código[cursor],'n'))
            {
                car = to!dstring('\n');
            }
            else if(mismocarácter(código[cursor],'r'))
            {
                car = to!dstring('\r');
            }
            else if(mismocarácter(código[cursor],'\''))
            {
                car = to!dstring('\'');
            }
            else if(mismocarácter(código[cursor],'\"'))
            {
                car = to!dstring('\"');
            }
            else if(mismocarácter(código[cursor],'\\'))
            {
                car = to!dstring('\\');
            }
            else if(mismocarácter(código[cursor],'0'))
            {
                car = to!dstring('\0');
            }
            else
            {
                aborta(módulo, línea, "No reconozco la secuencia de escape");
            }
        }
        else
        {
            car = to!dstring(código[cursor]);
        }
        
        cursor++;

        l.categoría = lexema_e.CARÁCTER;
        l.símbolo   = car;
        l.línea     = línea;

        if(!mismocarácter(código[cursor],'\''))
        {
            cursor = c;
            esperaba(módulo, línea, "un cierre de comilla simple [\']");
        }

        cursor++;

        análisis ~= l;

        return true;
    }
    else
    {
        return false;
    }
}

private bool tipo()
{
    bool resultado = false;

    uint c = cursor;

    if(_nombre())
    {
        dstring s = código[c..cursor];

        if(s.length < 2)
        {
            resultado = false;
            return resultado;
        }
        
        if(s == "nada")
        {
            resultado = true;
            
            lexema l;
            l.categoría = lexema_e.TIPO;
            l.símbolo   = s;
            l.línea     = línea;

            análisis ~= l;
        }
        else if(mismocarácter(s[0], 'n') | mismocarácter(s[0], 'e') | mismocarácter(s[0], 'r'))
        {
            for(int i = 1; i < s.length; i++)
            {
                if(!esdígito(s[i]))
                {
                    cursor = c;
                    return false;
                }
            }

            resultado = true;
            
            lexema l;
            l.categoría = lexema_e.TIPO;
            l.símbolo   = s;
            l.línea     = línea;

            análisis ~= l;

            // uint n = to!int(s[1..$]);
        }
        else
        {
            cursor = c;
            resultado = false;
        }
    }

    return resultado;
}

private bool identificador()
{
    return (_registro() | _idlocal() | _idglobal);
}

private bool _idglobal()
{
    bool resultado = false;

    uint c = cursor;

    if(mismocarácter(código[cursor], '@'))
    {
        cursor++;
        resultado = _nombre();
    }

    if(resultado)
    {
        dstring s = código[c .. cursor];
        
        lexema l;
        l.categoría = lexema_e.IDENTIFICADOR;
        l.símbolo = s;
        l.línea = línea;

        análisis ~= l;

        return true;
    }

    cursor = c;

    return resultado;
}

private bool _idlocal()
{
    bool resultado = false;

    uint c = cursor;

    if(mismocarácter(código[cursor], '%'))
    {
        cursor++;
        resultado = _nombre();
    }

    if(resultado)
    {
        dstring s = código[c .. cursor];
        
        lexema l;
        l.categoría = lexema_e.IDENTIFICADOR;
        l.símbolo = s;
        l.línea = línea;

        análisis ~= l;

        return true;
    }

    cursor = c;

    return resultado;
}

private bool _registro()
{
    bool resultado = false;

    uint c = cursor;

    if(mismocarácter(código[cursor], '%'))
    {
        cursor++;
        if(esdígito(código[cursor]))
        {
            while(esdígito(código[cursor])) {
                /*
                if(cursor == (código.length+1))
                {
                    break;
                }
                */
                cursor++;
            } 

            dstring s = código[c .. cursor];

            //int n = to!int(código[c+1 .. cursor]);
            
            lexema l;
            l.categoría = lexema_e.IDENTIFICADOR;
            l.símbolo = s;
            l.línea = línea;
            análisis ~= l;

            return true;
        }
    }

    cursor = c;

    return false;
}

private bool operación()
{
    bool resultado = false;

    uint c = cursor;

    if(_nombre())
    {
        dstring s = código[c..cursor];

        if((s == "mov")
         | (s == "sum")
         | (s == "res")
         | (s == "mul")
         | (s == "div")
         | (s == "rsrva")
         | (s == "lee")
         | (s == "guarda")
         | (s == "cmp")
         | (s == "slt")
         | (s == "llama")
         | (s == "ret")
         | (s == "conv")
         | (s == "phi")
         | (s == "leeval")
         | (s == "ponval")
         )
        {
            resultado = true;
            
            lexema l;
            l.categoría = lexema_e.OPERACIÓN;
            l.símbolo = s;
            l.línea = línea;

            análisis ~= l;
        }
        else
        {
            cursor = c;
        }
    }

    return resultado;
}

private bool nombre()
{
    bool resultado = false;

    uint c = cursor;

    if(esletra(código[cursor]))
    {
        resultado = true;
        do {
            if(cursor == (código.length+1))
            {
                return true;
            }
            cursor++;
        } while(esalfanum(código[cursor]));
    }

    if(resultado)
    {
        dstring s = código[c..cursor];
            
        lexema l;
        l.categoría = lexema_e.NOMBRE;
        l.símbolo = s;
        l.línea = línea;

        análisis ~= l;
    }

    return resultado;
}