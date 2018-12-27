module apoyo;

dstring módulo = "Apoyo.d";

import arbol;
import core.stdc.stdlib; // exit();
import std.conv;
import std.file; // File(), exists(), f.eof(), f.close()
import std.stdint; // uint64_t y demás tipos
import std.stdio; // write(), writeln()
import std.uni; // isAlpha(), isNumber(), isAlphaNum(), isWhite()
import std.utf; // toUTF32()

bool CHARLATÁN = false;
bool INFO = false;
bool AVISO = true;

dstring archivo;

class posición3d
{
    uint64_t    línea;
    uint64_t    columna;
    uint64_t    desplazamiento;
}

class lexema
{
    lexema_e    categoría;
    dstring     símbolo;
    posición3d  posición;

    this()
    {
        posición = new posición3d();
    }
}

enum lexema_e
{
    ETIQUETA,
    RESERVADA,
    TIPO,
    OPERACIÓN,
    IDENTIFICADOR,
    NÚMERO,
    CARÁCTER,
    TEXTO,
    REGISTRO,
    NOTACIÓN,
    NOMBRE,
    
    FDA // Final De Archivo
}

// 'TablaIdentificadores' implementa la tabla de identificadores.
// Para ello usa un diccionario:
// Para acceder a cada una de las entradas, se usa el nombre del identificador.
// A través del diccionario la estructura 'EntradaTablaIdentificadores', que
// contiene, entre otros, el Nodo 'declaración', el Nodo 'definición' y, en su
// caso, el Literal del 'valor actual'.
class TablaIdentificadores
{
    Nodo dueño;

    dstring _última_etiqueta;

    this(Nodo dueño)
    {
        this.dueño = dueño;
    }

    void última_etiqueta(dstring última_etiqueta)
    {
        this._última_etiqueta = última_etiqueta;
    }

    dstring última_etiqueta()
    {
        return this._última_etiqueta;
    }

    EntradaTablaIdentificadores[dstring] tabla;

    EntradaTablaIdentificadores[dstring] dame_tabla()
    {
        return this.tabla;
    }

    EntradaTablaIdentificadores coge_id(dstring identificador)
    {

        dstring id = identificador;

        if((identificador[0] == '@') || (identificador[0] == '%'))
        {
            id = identificador; // identificador[1..$];
        }

        auto tmp = id in tabla;

        if(tmp is null) //el identificador no se encuentra en la tabla actual
        {
            // devuelve una entrada nula
            return EntradaTablaIdentificadores(null, false, null, false, null, null);
        }
        else //el identificador se encuentra en la tabla actual
        {
            tabla[id].usado = true;
            return tabla[id];
        }
    }

    EntradaTablaIdentificadores lee_id(dstring identificador)
    {

        dstring id = identificador;

        if((identificador[0] == '@') || (identificador[0] == '%'))
        {
            id = identificador; // identificador[1..$];
        }

        auto tmp = id in tabla;

        if(tmp is null) //el identificador no se encuentra en la tabla actual
        {
            // devuelve una entrada nula
            return EntradaTablaIdentificadores(null, false, null, false, null, null);
        }
        else //el identificador se encuentra en la tabla actual
        {
            return tabla[id];
        }
    }

    void encuentra_ids_no_usados()
    {
        /*
        foreach(eid; tabla)
        {
            if(eid.nombre !is null)
            {
                if(eid.usado)
                {
                    write("[X] ");
                }
                else if(!eid.usado)
                {
                    write("[ ] ");
                }

                writeln(eid.nombre);
            }
        }
        */

        foreach(ref EntradaTablaIdentificadores eid; this.tabla)
        {
            if(eid.nombre is null)
            {
                aborta(módulo, null, "eid.nombre es nulo");
            }
            else if(eid.nombre == ":")
            {
                continue;
            }
            else if(!eid.usado)
            {
                posición3d pos = null;
                
                if(eid.declarado && eid.declaración !is null)
                {
                    pos = eid.declaración.posición;
                }
                else if(eid.definido && eid.definición !is null)
                {
                    pos = eid.definición.posición;
                }
                else if(eid.nombre[0] == ':')
                {
                    pos = eid.valor.posición;
                }
                avisa(módulo, pos, "No has usado el identificador '" ~ eid.nombre ~ "'");
            }
        }
    }

    bool declara_identificador(dstring identificador, Nodo declaración)
    {
        if(identificador is null)
        {
            if(declaración is null)
            {
                aborta("Apoyo.d", null, "Me has pasado un identificador nulo");
            }
            else
            {
                aborta("Apoyo.d", declaración.posición, "Me has pasado un identificador nulo");
            }
            
            return false;
        }

        dstring id = identificador;

        if((identificador[0] == '@') || (identificador[0] == '%'))
        {
            id = identificador; // identificador[1..$];
        }

        EntradaTablaIdentificadores eid;

        if(identificador in tabla)
        {
            eid = tabla[identificador];

            if(eid.declarado)
            {
                aborta("Apoyo.d", declaración.posición, "El identidicador ya se había declarado.");
            }
        }

        eid.nombre = id;
        eid.declarado = true;
        eid.declaración = declaración;

        tabla[id] = eid;

        return true;
    }

    Literal* crea_ptr_local(Tipo t)
    {
        uint64_t idx = 0;

        while((to!dstring(idx) in tabla) !is null)
        {
            idx++;
        }

        dstring id = to!dstring(idx);

        EntradaTablaIdentificadores eid;

        eid.valor = new Literal;
        eid.valor.tipo = t;

        tabla[id] = eid;

        Literal* ptr = &(tabla[id].valor);

        return ptr; // Literal*
    }

    bool define_identificador(dstring identificador, Nodo definición, Literal valor)
    {
        if(identificador is null)
        {
            if(definición is null)
            {
                aborta("Apoyo.d", null, "Me has pasado un identificador nulo");
            }
            else
            {
                aborta("Apoyo.d", definición.posición, "Me has pasado un identificador nulo");
            }
            
            return false;
        }

        EntradaTablaIdentificadores eid;

        if(identificador in tabla)
        {
            eid = tabla[identificador];
        }

        eid.nombre = identificador;
        eid.definido = true;
        eid.definición = definición;
        eid.valor = valor;

        tabla[identificador] = eid;

        return true;
    }
}

struct EntradaTablaIdentificadores
{
    dstring nombre;
    bool    declarado;
    Nodo    declaración;
    bool    definido;
    Nodo    definición;
    Literal valor;
    bool    usado;
}

void infoln()
{
    if(INFO)
    {
        stdout.writeln();
        stdout.flush();
    }
}

void infoln(dstring txt)
{
    if(INFO)
    {
        stdout.writeln(txt);
        stdout.flush();
    }
}

void info(dstring txt)
{
    if(INFO)
    {
        stdout.write(txt);
        stdout.flush();
    }
}

void charlatánln()
{
    if(CHARLATÁN)
    {
        stdout.writeln();
        stdout.flush();
    }
}

void charlatánln(dstring txt)
{
    if(CHARLATÁN)
    {
        stdout.writeln(txt);
        stdout.flush();
    }
}

void charlatán(dstring txt)
{
    if(CHARLATÁN)
    {
        stdout.write(txt);
        stdout.flush();
    }
}

void error(dstring módulo, posición3d posición, dstring s)
{
    if(posición is null)
    {
        stdout.writeln("ERROR [" ~ archivo ~ "] ", s, ". [MODULO: ", módulo, "]");
    }
    else
    {
        stdout.writeln("ERROR [" ~ archivo ~ " - L:", to!dstring(posición.línea), "] ", s, ". [MODULO: ", módulo, "]");
    }
    stdout.flush();
}

void avisa(dstring módulo, posición3d posición, dstring s)
{
    if(AVISO)
    {
        if(posición is null)
        {
            stdout.writeln("AVISO [" ~ archivo ~ "] ", s, ". [MODULO: ", módulo, "]");
        }
        else
        {
            stdout.writeln("AVISO [" ~ archivo ~ " - L:", to!dstring(posición.línea), "] ", s, ". [MODULO: ", módulo, "]");
        }
        stdout.flush();
    }
}

void aborta(dstring módulo, posición3d posición, dstring s)
{
    error(módulo, posición, s);
    exit(-1);
}

void esperaba(dstring módulo, posición3d posición, dstring s)
{
    dstring mensaje = "Esperaba ";
    mensaje ~= s;
    aborta(módulo, posición, mensaje);
}


dstring leearchivo(dstring archivo)
{
    if(!exists(archivo))
    {
        stdout.writeln("ERROR");
        stdout.flush();
    }

    File Fuente = File(archivo, "r");

    dstring cod = "";

    while(!Fuente.eof())
    {
        cod ~= toUTF32(Fuente.readln());
    }

    Fuente.close();

    return cod;
}

bool mismocarácter(dchar c, dchar x)
{
    return c == x;
}

bool esespacio(dchar c)
{
    return isWhite(c);
}

bool esletra(dchar c)
{
    dchar subrayado = '_';
    bool s = (subrayado == c);

    dchar punto = '.';
    bool p = (punto == c);

    dchar almohadilla = '#';
    bool alm = (almohadilla == c);


    bool a = isAlpha(c);


    return s || a || p || alm;
}

bool esdígito(dchar c)
{
    return isNumber(c);
}

bool esalfanum(dchar c)
{
    dchar subrayado = '_';
    bool s = (subrayado == c);

    dchar punto = '.';
    bool p = (punto == c);

    dchar almohadilla = '#';
    bool alm = (almohadilla == c);

    dchar másque = '>';
    bool ma = (másque == c);

    dchar menosque = '<';
    bool me = (menosque == c);


    bool a = isAlphaNum(c);


    return s || a || p || alm || ma || me;
}