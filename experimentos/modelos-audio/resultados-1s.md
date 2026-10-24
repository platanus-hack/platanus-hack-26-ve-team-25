# Resultados con ventanas de 1 s

Clips de ESC-50 por clase: 40. CPU de escritorio, un hilo.

| modelo                      |    MB |   ms por 1 s de audio | acierto top-5   |   minutos de prueba |
|:----------------------------|------:|----------------------:|:----------------|--------------------:|
| YAMNet (TFLite)             |   4.1 |                   2.5 | 82%             |                 0.2 |
| EfficientAT mn04            |   4.3 |                   3.8 | 64%             |                 0.3 |
| EfficientAT mn10            |  19.8 |                   6.4 | 0%              |                 0.5 |
| PANNs MobileNetV1           |  23.6 |                   5.2 | 76%             |                 0.4 |
| PANNs Cnn14                 | 327.3 |                  66.6 | 81%             |                 5.2 |
| sherpa CED tiny int8        |   6.1 |                   5.8 | 54%             |                 0.5 |
| sherpa CED mini int8        |  10.5 |                   7.9 | 55%             |                 0.6 |
| sherpa CED mini             |  39.1 |                  10.6 | 56%             |                 0.8 |
| sherpa Zipformer small int8 |  27   |                  25.9 | 81%             |                 2   |

## Acierto top-5 por clase

|                  | YAMNet (TFLite)   | EfficientAT mn04   | EfficientAT mn10   | PANNs MobileNetV1   | PANNs Cnn14   | sherpa CED tiny int8   | sherpa CED mini int8   | sherpa CED mini   | sherpa Zipformer small int8   |
|:-----------------|:------------------|:-------------------|:-------------------|:--------------------|:--------------|:-----------------------|:-----------------------|:------------------|:------------------------------|
| glass_breaking   | 90%               | 60%                | 0%                 | 92%                 | 100%          | 20%                    | 35%                    | 30%               | 82%                           |
| door_wood_knock  | 95%               | 75%                | 0%                 | 98%                 | 95%           | 72%                    | 88%                    | 88%               | 95%                           |
| clock_alarm      | 98%               | 90%                | 0%                 | 100%                | 98%           | 92%                    | 100%                   | 100%              | 98%                           |
| siren            | 98%               | 100%               | 0%                 | 100%                | 98%           | 100%                   | 100%                   | 100%              | 100%                          |
| crying_baby      | 92%               | 98%                | 0%                 | 88%                 | 85%           | 52%                    | 60%                    | 62%               | 95%                           |
| coughing         | 92%               | 90%                | 0%                 | 100%                | 100%          | 52%                    | 70%                    | 68%               | 100%                          |
| sneezing         | 95%               | 60%                | 0%                 | 85%                 | 90%           | 18%                    | 8%                     | 8%                | 82%                           |
| breathing        | 100%              | 95%                | 0%                 | 92%                 | 100%          | 95%                    | 82%                    | 82%               | 100%                          |
| snoring          | 100%              | 85%                | 0%                 | 85%                 | 85%           | 82%                    | 80%                    | 78%               | 82%                           |
| laughing         | 85%               | 28%                | 0%                 | 70%                 | 75%           | 62%                    | 78%                    | 75%               | 98%                           |
| footsteps        | 70%               | 48%                | 0%                 | 48%                 | 62%           | 50%                    | 52%                    | 55%               | 75%                           |
| toilet_flush     | 100%              | 48%                | 0%                 | 98%                 | 100%          | 48%                    | 20%                    | 22%               | 98%                           |
| pouring_water    | 100%              | 100%               | 0%                 | 98%                 | 100%          | 100%                   | 92%                    | 95%               | 100%                          |
| door_wood_creaks | 28%               | 8%                 | 0%                 | 28%                 | 15%           | 0%                     | 0%                     | 2%                | 30%                           |
| vacuum_cleaner   | 65%               | 35%                | 0%                 | 35%                 | 85%           | 20%                    | 20%                    | 22%               | 52%                           |
| washing_machine  | 10%               | 2%                 | 0%                 | 8%                  | 5%            | 2%                     | 2%                     | 2%                | 2%                            |
