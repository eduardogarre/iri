# **RIE - Representación Intermedia, en Español**

RIE es un lenguaje de Representación Intermedia creado con el objetivo de ser capaz de representar lenguajes de alto nivel con sintaxis en español.

RIE pretende ser ligero, por lo que usa abstracciones de bajo nivel, sin renunciar a ser expresivo, tipado y extensible. El objetivo de RIE es ser un lenguaje de representación intermedia universal: que pudiera ser usado como representación intermedia, potencialmente, por cualquier lenguaje de alto nivel.

Además, puesto que RIE es un lenguaje tipado y con la propiedad de la asignación única estática, permite más opciones en las fases de análisis, optimización e interpretación/producción de código, generando programas potencialmente más eficientes.

Aquí tienes un ejemplo en RIE, para multiplicar la variable `%var` por `8`:
`%resultado = mul e32 %var, 8;`

## Estructura general
Los programas de RIE se dividen en módulos, siendo cada módulo el resultado de la traducción de una unidad de un lenguaje de más alto nivel.
En general, cada módulo se compone de listas de declaraciones y definiciones globales: funciones y variables. Aquí tienes un ejemplo del módulo `hola`, en el archivo `hola.ri`, que imprime el texto `hola, mundo.`:

```
//Código de ejemplo
módulo hola;

// define la función @escribe(), que recibe como argumento una lista de caracteres.
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

// Defino la variable global %txt, que contiene el texto
@txt = "hola, mundo.";

// La función @inicio() es el punto de inicio de la ejecución del programa
define e32 @inicio(r32 %pi)
{
    llama nada @escribe(@txt);
    ret e32 0;
}
```

En primer lugar, la línea #2 establece el nombre del módulo:
> `módulo hola;`

A continuación se suceden 3 definiciones, de la función `@escribe()` en la línea #5, de la variable global `@txt` en la línea #30, y de la función `@inicio()` en la línea #32.

## Identificadores
En general, el formato del identificador, global o local, es el siguiente:
> `[%@][a-zA-Z.\_\#][a-zA-Z.\_\#<>0-9]*`

Algunos ejemplos de identificadores válidos serían: `@hola`, `%adiós`, `%2048`, `@nrm.es.escribe`, `@#poncar`, `%var<mitipo>`, `@función#mitipo2#mitipo3`, etc...

Los identificadores empiezan con un prefijo por dos motivos:
 - Evitar que los identificadores de los lenguajes de alto nivel colisionen con las palabras reservadas de RIE
 - Permitir el uso de identificadores sin nombre (registros) mediante números precedidos de `%`, p.ej `%0`, `%42`, `%288`.

##### Ámbito de los identificadores
En cuanto al ámbito, en RIE los identificadores se dividen en 2 clases:

**Globales:** Funciones o variables. Empiezan por el carácter '@'
> Por ejemplo: `@función()`, `@var_global`

**Locales:** Registros, tipos o variables. Empiezan con el carácter '%'
> Por ejemplo: `%var_local`, `%42`, `%mi_tipo`

## Palabras reservadas
Las palabras reservadas de RIE son muy intuitivas. Hay claves para las operaciones (`sum`, `res`, `mul`, `llama`, `cmp`, `ret`, etc...), para los tipos básicos (`nada`, `n64`, `e32`, `r32`, etc...), y otras (`define`, `declara`, `módulo`, etc...). Todas estas palabras no pueden colisionar con los identificadores porque ninguna comienza por los prefijos `%` ó `@`. Las palabras reservadas se pueden agrupar por categorías: 
 - Instrucciones: `ret`, `sum`, `res`, `mul`, `div`, `cmp`, `slt`, `phi`, `conv`, `llama`, `rsrva`, `lee`, `guarda`, `leeval`, `ponval`.
 - Comparadores: `ig`, `dsig`, `ma`, `me`, `maig`, `meig`, `y`, `o`, `no`, `oex`.
 - Tipos: `nada`, `n1-64`, `e2-64`, `r16|32|64`.
 - Valores: `cierto`, `falso`.
 - Otras: `módulo`, `define`, `declara`, `tipo`, `global`, `local`, `x`, `a`.

## Tipos
El sistema de tipos de RIE se compone de tipos básicos y compuestos.

Los tipos básicos son los enteros, los naturales y los reales, además del tipo especial `nada`. A la hora de usar los tipos, siempre debemos definir el espacio que asignaremos al tipo, de la siguiente forma: los enteros en el rango e2-64 (p.ej `e32` es un entero de 32 dígitos), los naturales en el rango n1-64 (siendo `n1` un tipo booleano, y `n16` un natural de 16dig sin signo), y los reales únicamente r16|32|64 (son válidos `r16`, `r32` y `r64`).

Los tipos compuestos son las listas y las estructuras. Las listas se definen como `[<tamaño> x <tipo>]`, p.ej `[12 x n32]`.

## Funciones
Las funciones se definen usando la palabra reservada `define`, y se declaran con la palabra reservada `declara`.
La estructura de una declaración de función es la siguiente:
```
declara <tipo_ret> @función(<tipo1> <arg1>, <tipo2> <arg2>...);
```
Siendo `<tipo_ret>` el tipo del valor devuelto, y los pares `<tipo#> <arg#>` los argumentos que recibe la función.

La definición de una función se estructura de la siguiente forma:
```
define <tipo_ret> @función(<tipo1> <arg1>, <tipo2> <arg2>...)
{
    ...
}
```
En la definición, además de cambiar la palabra reservada se añade un bloque con el contenido de la función. El bloque se compondrá de asignaciones a identificadores locales (registros, variables locales o tipos), instrucciones y etiquetas. Todas las funciones deben terminar con una de las versiones de la instrucción `ret`.

## Listado de instrucciones
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

La instrucción `sum` guarda en `%resultado` la suma de los argumentos `<valor1>` y `<valor2>`.

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
%b = res r32 3.14, 1e-1; // %a:r32 = 3.04
```


### mul
`%resultado = mul <tipo> <valor1>, <valor2>;`

La instrucción `mul` guarda en `%resultado` la multiplicación de los argumentos `<valor1>` por `<valor2>`.

##### ejemplos:
```
%a = mul n32 1, 10; // %a:n32 = 1
%b = mul r32 3.14, 1e3; // %a:r32 = 3140
```

### div
`%resultado = div <tipo> <valor1>, <valor2>;`

La instrucción `div` guarda en `%resultado` la división de los argumentos `<valor1>` entre `<valor2>`.

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
// ejecuta la función @escribe()
llama nada @escribe(@txt);

// ejecuta la función @mates.pot()
// guarda el resultado (un real de 32 dígitos) en %a
%a = llama r32 @mates.pot(4, 8); 
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
...
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
`%res = rsrva <tipo>`
Reserva espacio en la pila actual para guardar una variable de tipo `<tipo>`, y guarda en `%res` la dirección.

##### ejemplo:
```
%ptr = rsrva e32;
```

### guarda
`guarda <tipo> <id>, <tipo_ptr>* <puntero>;`
Guarda el contenido de `<id>` en la dirección de memoria indicada por `<puntero>`.

##### ejemplo:
```
guarda e32 42, e32* %ptr;
```

### lee
`%res = lee <tipo>, <tipo_ptr>* <puntero>;`
Lee el contenido de la dirección de memoria indicada por `<puntero>`, y lo escribe en la variable `%res`.

##### ejemplo:
```
%res = lee e32, e32* %ptr;
```

### leeval
`%res = leeval <tipo_lista> <identificador>, <índice>;`
En la lista indicada por `<identificador>`, de tipo `<tipo_lista>`, lee el elemento de la posición `<índice>`, y lo escribe en la variable `%res`.

##### ejemplo:
```
%res = leeval [6 x n32] %txt, %0;
```

### ponval
`%res = ponval <tipo_lista> <literal_lista>, <tipo> <literal>, <índice>`
En la lista indicada por `<literal_lista>`, en la posición indicada por `<índice>`, guarda el literal indicado por `<tipo> <literal>`. Devuelve la nueva lista resultante, guardándola en `%res`.

##### ejemplo:
```
@txt = "hola, mundo.";
...
`%res = ponval [12 x n32] @txt, n32 'H', 0`; // %res = "Hola, mundo."
```


## Funciones internas del intérprete
#### @#poncar(n32 %carácter);
Imprime un carácter
##### Aviso
Disponible únicamente si ejecutas el programa RIE con el intérprete `iri`.

## Licencia
Publicado bajo la Licencia de Programación Libre 0.1 ("LPL 0.1").
https://github.com/Hispanica/licencias
