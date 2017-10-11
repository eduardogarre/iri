module apoyo;

import arbol;
import core.stdc.stdlib; // exit();
import std.file; // File(), exists(), f.eof(), f.close()
import std.stdint; // uint64_t y demás tipos
import std.stdio; // write(), writeln()
import std.uni; // isAlpha(), isNumber(), isAlphaNum(), isWhite()
import std.utf; // toUTF32()

bool CHARLATÁN = false;
bool INFO = false;


struct lexema
{
    lexema_e    categoría;
    dstring     símbolo;
    uint64_t    línea;
}

enum lexema_e
{
    ETIQUETA,
    RESERVADA,
    TIPO,
    OPERACIÓN,
    IDENTIFICADOR,
    NÚMERO,
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
                aborta("No habías declarado el id " ~ identificador);
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

struct EntradaTablaIdentificadores
{
    dstring nombre;
    bool    declarado;
    Nodo    declaración;
    bool    definido;
    Nodo    definición;
    Literal valor;
}

void infoln()
{
    if(INFO)
    {
        writeln();
    }
}

void infoln(dstring txt)
{
    if(INFO)
    {
        writeln(txt);
    }
}

void info(dstring txt)
{
    if(INFO)
    {
        write(txt);
    }
}

void charlatánln()
{
    if(CHARLATÁN)
    {
        writeln();
    }
}

void charlatánln(dstring txt)
{
    if(CHARLATÁN)
    {
        writeln(txt);
    }
}

void charlatán(dstring txt)
{
    if(CHARLATÁN)
    {
        write(txt);
    }
}

void error(dstring s)
{
    stdout.writeln("ERROR: "d, s, ".");
}

void aborta(dstring s)
{
    error(s);
    exit(0);
}

void esperaba(dstring s)
{
    dstring mensaje = "Esperaba ";
    mensaje ~= s;
    aborta(mensaje);
}


dstring leearchivo(dstring archivo)
{
    if(!exists(archivo))
    {
        writeln("ERROR");
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

    bool a = isAlpha(c);


    return s || a;
}

bool esdígito(dchar c)
{
    return isNumber(c);
}

bool esalfanum(dchar c)
{
    dchar subrayado = '_';
    bool s = (subrayado == c);

    bool a = isAlphaNum(c);


    return s || a;
}