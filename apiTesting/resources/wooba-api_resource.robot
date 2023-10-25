*** Settings ***
library   RequestsLibrary
library   String
Library   Collections
Library   FakerLibrary    locale=pt_BR
Library   DateTime

*** Keywords ***

Criar sessão do wooba-api
    ${headers}        Create Dictionary
    ...               accept=application/json
    ...               Content-Type=application/json
    Create Session    alias=WoobaApi    url=https://dev-wooba-api-skyteam.plataforma13.com.br    headers=${headers}

Realizar pesquisa somente ida nacional
    [Arguments]    ${departure-iata}  ${arrival-iata}
    Criar sessão do wooba-api
    ${date_outbound}       FakerLibrary.Future Date
    ${resposta_pesquisa_oneway}    GET On Session
    ...                            alias=WoobaApi
    ...                            url=/search?trip=oneway&departure-iata=${departure-iata}&arrival-iata=${arrival-iata}&cabin=3&outbound-date=${date_outbound}&adults=1&children=0&babies=0
    ...                            expected_status=200
    log  ${resposta_pesquisa_oneway}

    Set Suite Variable    ${resposta_pesquisa_oneway}    ${resposta_pesquisa_oneway}

Armazenar dados da pesquisa    
    Set Suite Variable    ${RESP_PESQUISA}   ${resposta_pesquisa_oneway.json()["DATA"]["OUTBOUND"]["FLIGHTS"][0]}
    Log    ${RESP_PESQUISA}
    Set Suite Variable    ${ID_PESQUISA}   ${resposta_pesquisa_oneway.json()["DATA"]["OUTBOUND"]["FLIGHTS"][0]["EMISSION_DATA"]["ID"]}
    Log    ${ID_PESQUISA}
    Set Suite Variable    ${IDENTIFICATION_PESQUISA}   ${resposta_pesquisa_oneway.json()["DATA"]["OUTBOUND"]["FLIGHTS"][0]["EMISSION_DATA"]["IDENTIFICATION"]}
    Log    ${IDENTIFICATION_PESQUISA}

Realizar validação do voo oneway
    
    ${body}        Create Dictionary
    ...            partnerCode=SKY
    ...            international=${false}
    ...            trip=oneway    
    ...            cabin=${3}
    ...            outboundId=${ID_PESQUISA}
    ...            outboundIdentification=${IDENTIFICATION_PESQUISA}
    ...            qtyAdults=${1}
    ...            qtyChilds=${0}
    ...            qtyBabies=${0}
    Log            ${body}

    ${resposta}    POST On Session
    ...            alias=WoobaApi
    ...            url=/fares
    ...            json=${body}
    Log            ${resposta.json()}

Realizar o processo de reserva oneway
    ${name}              FakerLibrary.name
    ${lastName}          FakerLibrary.lastName
    ${birthdate}         FakerLibrary.date_of_birth     minimum_age=18  maximum_age=60
    ${format_birthdate}  Convert To String    ${birthdate}
    ${documentCPF}       FakerLibrary.CPF
    ${CPF}               Replace String   	${documentCPF}   	.   	${EMPTY}
    ${CPF}           	 Replace String   	${CPF}   	-   	${EMPTY}
    ${email}             FakerLibrary.email
    ${city}              FakerLibrary.city
    ${fullName}          Catenate    ${name}    ${lastName}

    ${internal_contacts}    Create Dictionary
    ...                     email=alteracao.convencional@milhasfacil.com
    ...                     address=Rua dos Aimores 1001 - 13

    ${phone}     Create Dictionary
    ...            city=${city}
    ...            mail=${email}
    ...            address=Rua dos Aimores 1001 - 13
    ...            ddiNumber=55
    ...            dddNumber=31
    ...            phoneNumber=999999999
    ...            name=${fullName}

    ${document}    Create Dictionary
    ...            type=CPF
    ...            number=${CPF}
    ...            nationality=BR
    ...            emissionCountry=BR

    ${passengers}  Create Dictionary
    ...            ageGroup=ADT
    ...            gender=M
    ...            birthdate=${format_birthdate}
    ...            name=${name}
    ...            middleName=
    ...            surname=${lastName}
    ...            phone=${phone}
    ...            document=${document}
    ...            cpfNumber=${CPF}
    
    ${passengerslist}  Create List
    ...                ${passengers}
    
    ${body}        Create Dictionary
    ...            outboundIdentification=${IDENTIFICATION_PESQUISA}
    ...            inboundIdentification=    
    ...            passengers=${passengerslist}  
    log            ${body}

    ${resposta_reserva}    POST On Session
    ...                    alias=WoobaApi
    ...                    url=/booking
    ...                    json=${body}
    log                    ${resposta_reserva.json}
    
    Set Suite Variable    ${resposta_reserva}    ${resposta_reserva}
    
Conferir se a reserva foi efetuada oneway    
    Set Suite Variable    ${LOCATOR}   ${resposta_reserva.json()["data"][0]["locator"]}
    Log    ${LOCATOR}
    Set Suite Variable    ${ID_RESERVA}   ${resposta_reserva.json()["data"][0]["id"]}
    Log    ${ID_RESERVA}
    Set Suite Variable    ${STATUS_RESERVA}   ${resposta_reserva.json()["data"][0]["status"]}
    Log    ${STATUS_RESERVA}

Realizar o booking info da reserva
    ${resposta_bookingInfo}    GET On Session
    ...                        alias=WoobaApi
    ...                        url=/booking/${LOCATOR}
    ...                        expected_status=200
    log                        ${resposta_bookingInfo.json()}

    Set Suite Variable    ${resposta_bookingInfo}    ${resposta_bookingInfo.json()}
    

Validar os dados retornados no booking info
    Dictionary Should Contain Item    ${resposta_bookingInfo["data"]}    locator    ${LOCATOR}
    Dictionary Should Contain Item    ${resposta_bookingInfo["data"]}    id         ${ID_RESERVA}
    Dictionary Should Contain Item    ${resposta_bookingInfo["data"]}    status     ${STATUS_RESERVA}

Realizar a chamada de cancelamento da reserva
    ${resposta_cancel}    DELETE On Session 
    ...                        alias=WoobaApi
    ...                        url=/booking/${LOCATOR}
    ...                        expected_status=200
    log                        ${resposta_cancel.json()}

    Set Suite Variable    ${resposta_cancel}    ${resposta_cancel.json()}

Validar o retorno da mensagem de cancelamento
    Dictionary Should Contain Item    ${resposta_cancel}  data  Reserva cancelada com sucesso (${LOCATOR})

Validar os dados retornados no booking info apos o cancelamento
    Dictionary Should Contain Item    ${resposta_bookingInfo["data"]}    locator    ${LOCATOR}
    Dictionary Should Contain Item    ${resposta_bookingInfo["data"]}    id         ${ID_RESERVA}
    Dictionary Should Contain Item    ${resposta_bookingInfo["data"]}    status     Cancelada

Realizar pesquisa ida e volta nacional
    [Arguments]    ${departure-iata}  ${arrival-iata}
    ${date_outbound}       FakerLibrary.Future Date
    ${date_inbound}        FakerLibrary.Future Date    tzinfo=${date_outbound}
    Criar sessão do wooba-api
    ${resposta_pesquisa_round}    GET On Session
    ...                     alias=WoobaApi
    ...                     url=/search?trip=round&departure-iata=${departure-iata}&arrival-iata=${arrival-iata}&cabin=3&outbound-date=${date_outbound}&inbound-date=${date_inbound}&adults=1&children=0&babies=0
    ...                     expected_status=200
    log  ${resposta_pesquisa_round}
    Set Test Variable    ${resposta_pesquisa_round}    ${resposta_pesquisa_round}

Armazenar dados da pesquisa ida e volta
    Set Test Variable    ${outboundId_round}   ${resposta_pesquisa_round.json()["DATA"]["GROUPS"][0]["OUTBOUND"][0]}
    ${outboundId_round}    Remove String    ${outboundId_round}    -3    
    Set Test Variable    ${inboundId_round}   ${resposta_pesquisa_round.json()["DATA"]["GROUPS"][0]["INBOUND"][0]}
    ${inboundId_round}    Remove String    ${inboundId_round}    -3    
    Set Suite Variable     ${unique_id_outbound}    ${resposta_pesquisa_round.json()["DATA"]["OUTBOUND"]["FLIGHTS"][0]["UNIQUE_ID"]}
    Set Suite Variable     ${flights_outbound}    ${resposta_pesquisa_round.json()["DATA"]["OUTBOUND"]["FLIGHTS"]}
    Set Suite Variable     ${unique_id_inbound}    ${resposta_pesquisa_round.json()["DATA"]["INBOUND"]["FLIGHTS"][0]["UNIQUE_ID"]}
    Set Suite Variable     ${flights_inbound}    ${resposta_pesquisa_round.json()["DATA"]["INBOUND"]["FLIGHTS"]}
    
    FOR    ${indice}    IN RANGE    0    20
           Set Suite Variable    ${flight_outbound}    ${flights_outbound[${indice}]}
           Exit For Loop If    "${flights_outbound[${indice}]["UNIQUE_ID"]}" == "${outboundId_round}"
    END

    FOR    ${indice}    IN RANGE    0    20
           Set Suite Variable    ${flight_inbound}    ${flights_inbound[${indice}]}
           Exit For Loop If    "${flights_inbound[${indice}]["UNIQUE_ID"]}" == "${inboundId_round}"
    END

    Set Suite Variable    ${id_outbound}                    ${flight_outbound["EMISSION_DATA"]["ID"]}
    Set Suite Variable    ${identification_outbound}        ${flight_outbound["EMISSION_DATA"]["IDENTIFICATION"]}
    Set Suite Variable    ${id_inbound}                     ${flight_inbound["EMISSION_DATA"]["ID"]}
    Set Suite Variable    ${identification_inbound}         ${flight_inbound["EMISSION_DATA"]["IDENTIFICATION"]}

Realizar validação do voo round
    ${body}        Create Dictionary
    ...            partnerCode=SKY
    ...            international=${false}
    ...            trip=round    
    ...            cabin=${3}
    ...            outboundId=${id_outbound}
    ...            outboundIdentification=${identification_outbound}
    ...            inboundId=${id_inbound}
    ...            inboundIdentification=${identification_inbound}        
    ...            qtyAdults=${1}
    ...            qtyChilds=${0}
    ...            qtyBabies=${0}
    Log            ${body}

    ${resposta}    POST On Session
    ...            alias=WoobaApi
    ...            url=/fares
    ...            json=${body}
    Log            ${resposta.json()}    

Realizar o processo de reserva round
    ${name}              FakerLibrary.name
    ${lastName}          FakerLibrary.lastName
    ${birthdate}         FakerLibrary.date_of_birth     minimum_age=18  maximum_age=60
    ${format_birthdate}  Convert To String    ${birthdate}
    ${documentCPF}       FakerLibrary.CPF
    ${CPF}               Replace String   	${documentCPF}   	.   	${EMPTY}
    ${CPF}           	 Replace String   	${CPF}   	-   	${EMPTY}
    ${email}             FakerLibrary.email
    ${city}              FakerLibrary.city
    ${fullName}          Catenate    ${name}    ${lastName}

    ${internal_contacts}    Create Dictionary
    ...                     email=alteracao.convencional@milhasfacil.com
    ...                     address=Rua dos Aimores 1001 - 13

    ${phone}     Create Dictionary
    ...            city=${city}
    ...            mail=${email}
    ...            address=Rua dos Aimores 1001 - 13
    ...            ddiNumber=55
    ...            dddNumber=31
    ...            phoneNumber=999999999
    ...            name=${fullName}

    ${document}    Create Dictionary
    ...            type=CPF
    ...            number=${CPF}
    ...            nationality=BR
    ...            emissionCountry=BR

    ${passengers}  Create Dictionary
    ...            ageGroup=ADT
    ...            gender=M
    ...            birthdate=${format_birthdate}
    ...            name=${name}
    ...            middleName=
    ...            surname=${lastName}
    ...            phone=${phone}
    ...            document=${document}
    ...            cpfNumber=${CPF}
    
    ${passengerslist}  Create List
    ...                ${passengers}
    
    ${body}        Create Dictionary
    ...            outboundIdentification=${identification_outbound}
    ...            inboundIdentification=${identification_inbound}
    ...            passengers=${passengerslist}  
    log            ${body}

    ${resposta_reserva_round}    POST On Session
    ...                          alias=WoobaApi
    ...                          url=/booking
    ...                          json=${body}
    log                          ${resposta_reserva_round.json}
    
    Set Suite Variable    ${resposta_reserva_round}    ${resposta_reserva_round} 

Conferir se a reserva foi efetuada round
    Set Suite Variable    ${LOCATOR}   ${resposta_reserva_round.json()["data"][0]["locator"]}
    Log    ${LOCATOR}
    Set Suite Variable    ${ID_RESERVA}   ${resposta_reserva_round.json()["data"][0]["id"]}
    Log    ${ID_RESERVA}
    Set Suite Variable    ${STATUS_RESERVA}   ${resposta_reserva_round.json()["data"][0]["status"]}
    Log    ${STATUS_RESERVA}    