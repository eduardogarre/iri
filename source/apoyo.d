module apoyo;

import core.stdc.stdlib; // exit();
import std.file; // File(), exists(), f.eof(), f.close()
import std.stdint; // uint64_t y demás tipos
import std.stdio; // write(), writeln()
import std.uni; // isAlpha(), isNumber(), isAlphaNum(), isWhite()
import std.utf; // toUTF32()

bool INFO;


struct lexema
{
    lexema_e    categoría;
    dstring     símbolo;
    uint64_t    línea;
}

enum lexema_e
{
    RESERVADA,
    TIPO,
    OPERACIÓN,
    IDENTIFICADOR,
    NÚMERO,
    TEXTO,
    REGISTRO,
    NOTACIÓN,
    NOMBRE
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