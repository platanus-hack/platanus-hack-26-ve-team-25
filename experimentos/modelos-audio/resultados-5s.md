# Resultados con ventanas de 5 s

Clips de ESC-50 por clase: 40. CPU de escritorio, un hilo.

| modelo                      |    MB |   ms por 1 s de audio | acierto top-5   |   minutos de prueba |
|:----------------------------|------:|----------------------:|:----------------|--------------------:|
| YAMNet (TFLite)             |   4.1 |                   4.8 | 81%             |                 0.3 |
| EfficientAT mn04            |   4.3 |                   4.4 | 83%             |                 0.2 |
| EfficientAT mn10            |  19.8 |                   5.4 | 79%             |                 0.3 |
| PANNs MobileNetV1           |  23.6 |                   5.5 | 80%             |                 0.3 |
| PANNs Cnn14                 | 327.3 |                  57.7 | 83%             |                 3.1 |
| sherpa CED tiny int8        |   6.1 |                   5.7 | 86%             |                 0.3 |
| sherpa CED mini int8        |  10.5 |                   7.4 | 87%             |                 0.4 |
| sherpa CED mini             |  39.1 |                   9.4 | 88%             |                 0.5 |
| sherpa Zipformer small int8 |  27   |                  22   | 87%             |                 1.4 |

## Acierto top-5 por clase

|                  | YAMNet (TFLite)   | EfficientAT mn04   | EfficientAT mn10   | PANNs MobileNetV1   | PANNs Cnn14   | sherpa CED tiny int8   | sherpa CED mini int8   | sherpa CED mini   | sherpa Zipformer small int8   |
|:-----------------|:------------------|:-------------------|:-------------------|:--------------------|:--------------|:-----------------------|:-----------------------|:------------------|:------------------------------|
| glass_breaking   | 92%               | 95%                | 95%                | 100%                | 95%           | 98%                    | 95%                    | 95%               | 98%                           |
| door_wood_knock  | 88%               | 95%                | 92%                | 98%                 | 95%           | 100%                   | 100%                   | 98%               | 95%                           |
| clock_alarm      | 98%               | 95%                | 98%                | 98%                 | 100%          | 90%                    | 98%                    | 98%               | 95%                           |
| siren            | 98%               | 98%                | 98%                | 100%                | 98%           | 98%                    | 100%                   | 100%              | 98%                           |
| crying_baby      | 92%               | 100%               | 100%               | 98%                 | 90%           | 98%                    | 98%                    | 98%               | 98%                           |
| coughing         | 92%               | 98%                | 95%                | 100%                | 92%           | 95%                    | 98%                    | 98%               | 100%                          |
| sneezing         | 95%               | 95%                | 98%                | 85%                 | 98%           | 95%                    | 92%                    | 98%               | 98%                           |
| breathing        | 98%               | 100%               | 98%                | 92%                 | 98%           | 100%                   | 100%                   | 100%              | 95%                           |
| snoring          | 100%              | 100%               | 100%               | 95%                 | 95%           | 98%                    | 100%                   | 100%              | 98%                           |
| laughing         | 82%               | 85%                | 92%                | 82%                 | 90%           | 92%                    | 98%                    | 98%               | 98%                           |
| footsteps        | 70%               | 52%                | 60%                | 52%                 | 68%           | 90%                    | 88%                    | 90%               | 82%                           |
| toilet_flush     | 98%               | 100%               | 100%               | 100%                | 100%          | 100%                   | 100%                   | 100%              | 100%                          |
| pouring_water    | 98%               | 100%               | 95%                | 100%                | 100%          | 100%                   | 100%                   | 100%              | 100%                          |
| door_wood_creaks | 25%               | 38%                | 20%                | 30%                 | 22%           | 55%                    | 38%                    | 45%               | 68%                           |
| vacuum_cleaner   | 62%               | 65%                | 28%                | 42%                 | 85%           | 72%                    | 75%                    | 78%               | 57%                           |
| washing_machine  | 12%               | 10%                | 2%                 | 5%                  | 5%            | 0%                     | 8%                     | 8%                | 8%                            |
