# derivatograph
! cpp app not finished
! приложение на cpp не закончено

Для измерения ЭДС двух платина--платина-родий термопар (Тип R или Тип S) используется 2 канала АЦП ad7793 в униполярном режиме с коэффициентом усиления 16. Подулючение АЦП к Ардуино по SPI. Дополнительных библиотек не требуется.
Для измерения массы используется тензодатчик с АЦП HX711. Необходима дополнительная библиотека к этому АЦП.

Приложение для ПК написанно на паскале (Lazarus IDE) с использование библиотеки Sdpo. Верхний график показывает изменение массы. Нижний график показывает изменение ЭДС на обоих термопарах. Красный - первый канал, Синий - второй канал.
