# RI - Representación Intermedia, en español

RI es un lenguaje de Representación Intermedia creado con el objetivo de ser capaz de representar lenguajes de alto nivel con sintaxis en español.

RI pretende ser ligero usando abstracciones de bajo nivel, pero también intenta ser expresivo, tipado y extensible. El objetivo de RI es ser una RI universal: un lenguaje de Representación Intermedia que pueda ser usado, potencialmente, por todos los lenguajes de alto nivel. Además RI es un lenguaje tipado, con el objetivo de permitir la posibilidad de realizar análisis y optimizaciones muy extensas.

#### Identificadores
Hay 2 clases de identificadores en RI:
  - Los identificadores globales (ya sean funciones o variables) empiezan por el carácter '@'
    Por ejemplo: `@función()`, `@variable`
  - Los identificadores locales (registros, tipos, variables) empiezan con el carácter '%'
    Por ejemplo: `%variable_local`, `%42`, `%mi_tipo`
En general, el formato del identificador es el siguiente: [%@][a-zA-Z.\_\#][a-zA-Z.\_\#<>0-9]*.
Por ejemplo:
`@hola`, `%adiós`, `%2048`, `@nrm.es.escribe`, `@#poncar`, `%var<mitipo>#función#mitipo2#mitipo3`, etc.

Los identificadores empiezan con un prefijo por dos motivos: para evitar que los identificadores de los lenguajes de alto nivel colisionen con las palabras reservadas de RI, y para permitir el uso de identificadores sin nombre (registros) mediante números precedidos de '%', p.ej `%0`, `%42`, `%288`.

Las palabras reservadas de RI son muy intuitivas. Hay claves para las operaciones (`sum`, `res`, `mul`, `llama`, `cmp`, `ret`, etc...), para los tipos básicos (`nada`, `n64`, `e32`, `r32`, etc...), y otras (`define`, `declara`, `módulo`, etc...). Todas estas palabras no pueden colisionar con los identificadores porque ninguna comienza por los prefijos `%` ó `@`.

Aquí tienes un ejemplo en RI, para multiplicar la variable %X por `8`:
`%resultado = mul e32 %X, 8;`


#### Estructura general
Los programas de RI se dividen en módulos, siendo cada módulo el resultado de la traducción de una unidad de un lenguaje de más alto nivel.
En general, cada módulo se compone de listas de valores globales: funciones y variables globales. Aquí tienes un ejemplo del módulo 'hola':

```
//Código de ejemplo
módulo hola;


define nada @escribe([0 x n32] %txt)
{
    // preparo el contador
    // para ponerlo a cero, guardo en él el resultado de 0+0
    %0 = sum e32 0, 0;

bucle:
    // obtengo un carácter de la lista %txt, el de la posición designada por %0
    %1 = leeval [6 x n32] %txt, %0;

    // incremento el contador
    %0 = sum e32 %0, 1;

    // escribo el carácter
    llama nada @#poncar(%1);

    // compruebo si el carácter es distinto a '\0'
    %2 = cmp dsig n32 %1, '\0';

    // mientras la comprobación sea cierta, salto a la etiqueta :bucle.
    slt n1 %2, :bucle;

    ret;
}

@txt = "hola, mundo.";

define e32 @inicio(r32 %pi)
{
    llama nada @escribe(@txt);
    ret e32 0;
}
```

Este ejemplo se compone de la variable global `@txt` y las definiciones de las funciones `@escribe()` e `@inicio()`.

#### Tipos
El sistema de tipos de RI se compone de tipos básicos y compuestos.

Los tipos básicos son los enteros, los naturales y los reales, además del tipo especial `nada`. A la hora de usar los tipos, siempre debemos definir el espacio que asignaremos al tipo, de la siguiente forma: los enteros en el rango e2-64 (p.ej `e32` es un entero de 32 dígitos), los naturales en el rango n1-64 (siendo `n1` un tipo booleano, y `n16` un natural de 16dig sin signo), y los reales únicamente r16|32|64 (son válidos `r16`, `r32` y `r64`).

Los tipos compuestos son las listas y las estructuras. Las listas se definen como `[<tamaño> x <tipo>]`, p.ej `[12 x n32]`.

#### Funciones
Las funciones se definen usando la palabra reservada `define`, y se declaran con la palabra reservada `declara`.
La estructura de una declaración de función es la siguiente:
```
declara <tipo_ret> @función(<tipo1> <arg1>, <tipo2> <arg2>...);
```
Y la definición de una función se estructura de la siguiente forma:
```
define <tipo_ret> @función(<tipo1> <arg1>, <tipo2> <arg2>...)
{
    ...
}
```

## Referencia de las instrucciones
### ret
`ret [<tipo> <valor>];`

La instrucción `ret` devuelve el control de la ejecución, desde la función actual, a la función que llamó a ésta. Hay 2 versiones de la instrucción `ret`: una versión que primero devuelve un valor y después devuelve el control de la ejecución, y otra versión que solo devuelve el control de ejecución.

##### ejemplos:
```
ret e32 0;
ret;
ret [12 x n32] "hola, mundo.";
```


### sum
`%resultado = sum <tipo> <valor1>, <valor2>;`

La instrucción `sum` guarda en `%resultado` la suma de los argumentos.

##### ejemplos:
```
%a = sum n32 1, 10; // %a:n32 = 11
%b = sum r32 3.14, 1e3; // %a:r32 = 1003.14
```


### res
`%resultado = res <tipo> <valor1>, <valor2>;`

La instrucción `res` guarda en `%resultado` la resta de `<valor1>` menos `<valor2>`.

##### ejemplos:
```
%a = res n32 10, 1; // %a:n32 = 9
%b = sum r32 3.14, 1e-1; // %a:r32 = 3.04
```


### mul
`%resultado = mul <tipo> <valor1>, <valor2>;`

La instrucción `mul` guarda en `%resultado` la multiplicación de los argumentos.

##### ejemplos:
```
%a = mul n32 1, 10; // %a:n32 = 1
%b = mul r32 3.14, 1e3; // %a:r32 = 3140
```

### div
`%resultado = div <tipo> <valor1>, <valor2>;`

La instrucción `div` guarda en `%resultado` la división de los argumentos.

##### ejemplos:
```
%a = div n32 10, 2; // %a:n32 = 5
%b = div r32 1e3, 3; // %a:r32 = 3.3333e2
```


### llama
`[%resultado =] llama <tipo> @<función>(<args>...);`

La instrucción `llama` pasa el control de la ejecución a otra función, proporcionándole los argumentos indicados.

##### ejemplos:
```
llama nada @escribe(@txt); // ejecuta la función @escribe()
%a = llama r32 @mates.pot(4, 8); // ejecuta la función @mates.pot(), y guarda el resultado en %a
```


### cmp
`%resultado = cmp <opcomp> <tipo> <valor1>, <valor2>;`

La instrucción `cmp` compara los valores usando una de las siguientes operaciones de comparación:
 - `ig` igualdad
 - `dsig` desigualdad
 - `ma` mayor que
 - `me` menor que
 - `maig` mayor o igual que
 - `meig` menor o igual que

##### ejemplo:
```
%0 = sum n32 0, 1; // %0 = n32:1
%a = cmp ig n32 %0, 1; // %a = n1:1, %a = cierto
```


### conv
`%resultado = conv <tipo_orig> <valor> a <tipo_dest>;`

La instrucción `conv` convierte `<valor>`, de tipo `<tipo_orig>`, al tipo destino `<tipo_dest>`.

##### ejemplos:
```
%res = conv n32 42 a e32; // %res = e32:42
```


### slt
 - `slt :etiqueta;`
 - `slt n1 <valor>, :etiqueta;`

La instrucción `slt` salta a la dirección de `:etiqueta` solo en el caso de `n1 <valor> == cierto`.
Si no se proporciona `n1 <valor>`, se salta incondicionalmente a la dirección de `:etiqueta`.

##### ejemplos:
```
slt :etiqueta; // salta a la dirección de :etiqueta
%0 = cmp ig e32 0, 0; // %0 = n1:cierto
slt n1 %0, :etiqueta; // salta a :etiqueta, puesto que %0 == n1:cierto
```


### phi
`%res = phi <tipo> [<valor1>, :etiqueta1], [<valor2>, :etiqueta2]...`

Esta instrucción implementa el nodo `phi` de la Asignación Única Estática. Selecciona el `<valor1>`, `<valor1>` ó sucesivos en función de si el flujo de ejecución procede de la `:etiqueta1`, `:etiqueta2` ó sucesivas. Una vez seleccionado el `<valor>`, lo guarda en `%res`

##### ejemplo:
```
etiq:
    %y = conv e6 %x a e32;
    ...
    %p = phi e32 [18, :etiq], [42, :adiós]; // %p = e32:18
```


### rsrva
Pdte

### lee
Pdte

### guarda
Pdte

### leeval
Pdte

### ponval
Pdte


## Funciones internas del intérprete
### @#poncar(n32 %carácter);
Imprime un carácter
##### Aviso
Disponible únicamente si ejecutas el programa RI con el intérprete.

## Licencia
Publicado bajo la Licencia de Programación Libre 0.1 ("LPL 0.1").
https://github.com/Hispanica/licencias