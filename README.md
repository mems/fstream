# Progressive font loader

AS3 library handle progressive font loading. Avoid one time load of large font like Unicode fonts, often embedding more than 10000 chars.

Librarie AS3 permettant de charger progressivement des polices dans Flash. Evitant ainsi le chargement en un seul bloc des polices lourdes comme les polices Unicodes, embarquant souvent plus de 10000 caractères.

```as3
var fontLoader:FontLoader = new FontLoader();
fontLoader.load(new FontChunksRequest("Arial Unicode MS", FontStyle.REGULAR, "Some text"));
```

See [Wiki pages](https://github.com/mems/fstream/wiki) and [Related posts](http://memmie.lenglet.name/tag/fstream) for more informations.

