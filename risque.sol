// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GestionnaireRisqueContrepartie {
    // Définition d'une structure pour une contrepartie
    struct Contrepartie {
        address portefeuille;
        uint256 scoreCredit;
        uint256 limiteExposition;
        uint256 expositionCourante;
        bool estActif;
    }

    // Variables d'état
    mapping(address => Contrepartie) public contreparties;
    mapping(address => mapping(address => uint256)) public expositions;
    
    // Historique des transactions
    mapping(address => uint256[]) public historiqueTransactions;  // Historique des expositions
    mapping(address => uint256) public nombreDepassements;         // Nombre de dépassements de limite

    // Événements
    event ContrepartieAjoutee(
        address indexed contrepartie,
        uint256 limiteExposition
    );
    event ExpositionMiseAJour(
        address indexed contrepartie,
        uint256 nouvelleExposition
    );
    event LimiteDepassee(
        address indexed contrepartie,
        uint256 exposition
    );

    // Fonction pour ajouter une contrepartie
    function ajouterContrepartie(
        address _contrepartie,
        uint256 _scoreCredit,
        uint256 _limiteExposition
    ) public {
        require(contreparties[_contrepartie].portefeuille == address(0), "La contrepartie existe deja");
        require(_contrepartie != address(0), "Adresse invalide");
        require(_limiteExposition > 0, "La limite d'exposition doit etre positive");

        // Ajouter ou mettre à jour les informations de la contrepartie
        contreparties[_contrepartie] = Contrepartie({
            portefeuille: _contrepartie,
            scoreCredit: _scoreCredit,
            limiteExposition: _limiteExposition,
            expositionCourante: 0,
            estActif: true
        });
        emit ContrepartieAjoutee(_contrepartie, _limiteExposition);
    }

    // Fonction pour mettre à jour l'exposition d'une contrepartie
    function mettreAJourExposition(address _contrepartie, uint256 _nouvelleExposition) public {
        require(contreparties[_contrepartie].estActif, "Contrepartie inactive");

        // Sauvegarder l'exposition courante dans l'historique
        historiqueTransactions[_contrepartie].push(contreparties[_contrepartie].expositionCourante);

        // Mettre à jour l'exposition courante de la contrepartie
        contreparties[_contrepartie].expositionCourante = _nouvelleExposition;

        // Vérification de dépassement de limite d'exposition
        if (_nouvelleExposition > contreparties[_contrepartie].limiteExposition) {
            nombreDepassements[_contrepartie]++;
            emit LimiteDepassee(_contrepartie, _nouvelleExposition);
        }

        // Émettre l'événement de mise à jour de l'exposition
        emit ExpositionMiseAJour(_contrepartie, _nouvelleExposition);
    }

// Fonction pour calculer le risque en fonction de l'exposition et du score de crédit
function calculerRisque(address _contrepartie) public view returns (uint256) {
    require(_contrepartie != address(0), "Adresse invalide");

    // Calcul simple du risque basé sur l'exposition et le score de crédit
    uint256 scoreCredit = contreparties[_contrepartie].scoreCredit;
    uint256 exposition = contreparties[_contrepartie].expositionCourante;

    // Risque calculé comme une fonction de l'exposition et du score de crédit
    if (scoreCredit == 0) {
        return type(uint256).max;  // Risque maximum si le score de crédit est nul
    }
    uint256 risque = (exposition * 100) / scoreCredit;  // Simple rapport de risque

    return risque;
}


    // Fonction pour récupérer l'historique des expositions d'une contrepartie
    function getHistoriqueTransactions(address _contrepartie) public view returns (uint256[] memory) {
        return historiqueTransactions[_contrepartie];
    }
}
