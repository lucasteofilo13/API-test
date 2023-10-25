*** Settings ***
Resource    ../resources/wooba-api_resource.robot

*** Variables ***
${departure-iata}    SAO
${arrival-iata}      RIO

*** Test Cases ***
Cenário 01: Realizar uma pesquisa de voo somente ida e validar o preço
    [tags]        pesquisa-oneway   reserva-oneway    cancel-oneway
    Realizar pesquisa somente ida nacional  departure-iata=${departure-iata}  arrival-iata=${arrival-iata}
    Armazenar dados da pesquisa
    Realizar validação do voo oneway

Cenário 02: Realizar a reserva do voo somente ida
    [tags]        reserva-oneway   cancel-oneway
    Realizar validação do voo oneway
    Realizar o processo de reserva oneway
    Conferir se a reserva foi efetuada oneway
    
Cenário 03: Realizar a booking info da reserva
    [tags]        reserva-oneway    cancel-oneway
    Conferir se a reserva foi efetuada oneway
    Realizar o booking info da reserva
    Validar os dados retornados no booking info

Cenário 04: Realizar uma pesquisa de voo ida e volta e validar o preço
    [tags]        pesquisa-round   reserva-round    cancel-round
    Realizar pesquisa ida e volta nacional   departure-iata=${departure-iata}  arrival-iata=${arrival-iata}
    Armazenar dados da pesquisa ida e volta
    Realizar validação do voo round

Cenário 05: Realizar a reserva do voo ida e volta
    [tags]        reserva-round    cancel-round
    Realizar validação do voo round
    Realizar o processo de reserva round
    Conferir se a reserva foi efetuada round

Cenário 06: Realizar a booking info da reserva round
    [tags]        reserva-round    cancel-round
    Conferir se a reserva foi efetuada round
    Realizar o booking info da reserva
    Validar os dados retornados no booking info

Cenário 07: Realizar o cancelamento da reserva
    [tags]        cancel-oneway    cancel-round
    Realizar a chamada de cancelamento da reserva
    Validar o retorno da mensagem de cancelamento

Cenário 08: Realizar o booking info para confirmar o cancelamento
    [tags]        cancel-oneway    cancel-round
    Realizar o booking info da reserva
    Validar os dados retornados no booking info apos o cancelamento